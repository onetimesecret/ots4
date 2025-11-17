defmodule OneTimeSecret.Secrets do
  @moduledoc """
  The Secrets context.

  This module provides the public API for managing secrets, including
  creating, retrieving, and burning (deleting) secrets.
  """
  import Ecto.Query
  alias OneTimeSecret.Repo
  alias OneTimeSecret.Secrets.{Secret, Metadata}
  alias OneTimeSecret.Cache

  require Logger

  @doc """
  Creates a new secret with optional passphrase protection.

  ## Options

    * `:content` - The secret content to encrypt (required)
    * `:passphrase` - Optional passphrase for additional protection
    * `:ttl` - Time to live in seconds (default: 3600, max: 604800)
    * `:max_views` - Maximum number of views (default: 1, max: 100)
    * `:recipient` - Optional recipient email
    * `:created_by` - Optional creator identifier

  ## Examples

      iex> create_secret(%{content: "my secret", ttl: 3600})
      {:ok, %{secret: %Secret{}, metadata: %Metadata{}}}

      iex> create_secret(%{content: "protected", passphrase: "password123"})
      {:ok, %{secret: %Secret{}, metadata: %Metadata{}}}
  """
  def create_secret(attrs \\ %{}) do
    secret_key = Secret.generate_key()
    metadata_key = Metadata.generate_key()

    passphrase_hash =
      case attrs[:passphrase] do
        nil -> nil
        "" -> nil
        passphrase -> Secret.hash_passphrase(passphrase)
      end

    secret_attrs = %{
      key: secret_key,
      content: attrs[:content],
      passphrase_hash: passphrase_hash,
      ttl: attrs[:ttl] || 3600,
      max_views: attrs[:max_views] || 1,
      metadata_key: metadata_key,
      recipient: attrs[:recipient],
      created_by: attrs[:created_by]
    }

    metadata_attrs = %{
      key: metadata_key,
      secret_key: secret_key,
      ttl: attrs[:ttl] || 3600,
      max_views: attrs[:max_views] || 1,
      expires_at: DateTime.utc_now() |> DateTime.add(attrs[:ttl] || 3600, :second),
      recipient: attrs[:recipient],
      passphrase_required: passphrase_hash != nil
    }

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:secret, Secret.changeset(%Secret{}, secret_attrs))
    |> Ecto.Multi.insert(:metadata, Metadata.changeset(%Metadata{}, metadata_attrs))
    |> Repo.transaction()
    |> case do
      {:ok, %{secret: secret, metadata: metadata}} ->
        # Store in cache for quick access
        Cache.put("secret:#{secret_key}", secret.id, secret_attrs.ttl)
        Logger.info("Created secret with key: #{secret_key}")
        {:ok, %{secret: secret, metadata: metadata}}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  @doc """
  Retrieves a secret by its key, optionally verifying passphrase.

  This function automatically increments the view count and deletes
  the secret if max_views is reached.

  ## Examples

      iex> get_secret("abc123")
      {:ok, %Secret{}}

      iex> get_secret("protected", "password123")
      {:ok, %Secret{}}

      iex> get_secret("nonexistent")
      {:error, :not_found}
  """
  def get_secret(key, passphrase \\ nil) do
    query = from(s in Secret, where: s.key == ^key)

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      secret ->
        # Check if expired
        if DateTime.compare(secret.expires_at, DateTime.utc_now()) == :lt do
          delete_secret(secret)
          {:error, :expired}
        else
          # Verify passphrase if required
          if secret.passphrase_hash do
            if passphrase && Secret.verify_passphrase(passphrase, secret.passphrase_hash) do
              increment_and_check_views(secret)
            else
              {:error, :invalid_passphrase}
            end
          else
            increment_and_check_views(secret)
          end
        end
    end
  end

  defp increment_and_check_views(secret) do
    new_view_count = secret.view_count + 1

    if new_view_count >= secret.max_views do
      # Last view - return secret and delete
      result = {:ok, secret}
      burn_secret(secret.key)
      result
    else
      # Increment view count
      secret
      |> Ecto.Changeset.change(%{view_count: new_view_count})
      |> Repo.update()
      |> case do
        {:ok, updated_secret} -> {:ok, updated_secret}
        error -> error
      end
    end
  end

  @doc """
  Immediately burns (deletes) a secret by its key.

  ## Examples

      iex> burn_secret("abc123")
      :ok
  """
  def burn_secret(key) do
    query = from(s in Secret, where: s.key == ^key)
    metadata_query = from(m in Metadata, where: m.secret_key == ^key)

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      secret ->
        Ecto.Multi.new()
        |> Ecto.Multi.delete(:secret, secret)
        |> Ecto.Multi.delete_all(:metadata, metadata_query)
        |> Repo.transaction()
        |> case do
          {:ok, _} ->
            Cache.delete("secret:#{key}")
            Logger.info("Burned secret with key: #{key}")
            :ok

          {:error, _failed_operation, failed_value, _changes_so_far} ->
            {:error, failed_value}
        end
    end
  end

  @doc """
  Retrieves metadata for a secret without accessing the content.

  ## Examples

      iex> get_metadata("meta123")
      {:ok, %Metadata{}}
  """
  def get_metadata(key) do
    query = from(m in Metadata, where: m.key == ^key)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      metadata -> {:ok, metadata}
    end
  end

  @doc """
  Lists all secrets (admin function - use with caution).
  """
  def list_secrets do
    Repo.all(Secret)
  end

  @doc """
  Deletes expired secrets from the database.
  This is called by the SecretSweeper worker.
  """
  def delete_expired_secrets do
    now = DateTime.utc_now()

    secret_query = from(s in Secret, where: s.expires_at < ^now)
    metadata_query = from(m in Metadata, where: m.expires_at < ^now)

    Ecto.Multi.new()
    |> Ecto.Multi.delete_all(:secrets, secret_query)
    |> Ecto.Multi.delete_all(:metadata, metadata_query)
    |> Repo.transaction()
    |> case do
      {:ok, %{secrets: {secret_count, _}, metadata: {metadata_count, _}}} ->
        if secret_count > 0 or metadata_count > 0 do
          Logger.info("Deleted #{secret_count} expired secrets and #{metadata_count} metadata records")
        end

        {:ok, secret_count}

      {:error, _failed_operation, failed_value, _changes_so_far} ->
        {:error, failed_value}
    end
  end

  defp delete_secret(secret) do
    Repo.delete(secret)
    Cache.delete("secret:#{secret.key}")
  end
end

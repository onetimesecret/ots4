defmodule OneTime.Secrets do
  @moduledoc """
  The Secrets context.

  Handles all operations related to creating, retrieving, and managing one-time secrets.
  """

  import Ecto.Query, warn: false
  alias OneTime.Repo
  alias OneTime.Secrets.Secret
  alias OneTime.Vault

  @doc """
  Creates a new secret.

  ## Options

    * `:content` - The secret content to encrypt (required)
    * `:passphrase` - Optional passphrase for additional protection
    * `:ttl` - Time to live in seconds (default: 7 days)
    * `:max_views` - Maximum number of views before burning (default: 1)
    * `:recipient` - Optional recipient email
    * `:metadata` - Optional metadata map
    * `:user_id` - Optional user ID if authenticated

  ## Examples

      iex> create_secret(%{content: "secret", ttl: 3600})
      {:ok, %Secret{}}

      iex> create_secret(%{content: "", ttl: 3600})
      {:error, %Ecto.Changeset{}}
  """
  def create_secret(attrs \\ %{}) do
    content = Map.get(attrs, :content) || Map.get(attrs, "content")
    passphrase = Map.get(attrs, :passphrase) || Map.get(attrs, "passphrase")
    ttl = Map.get(attrs, :ttl) || Map.get(attrs, "ttl") || default_ttl()

    max_secret_size = Application.get_env(:onetime, :max_secret_size, 1_048_576)

    with :ok <- validate_content_size(content, max_secret_size),
         {:ok, {ciphertext, nonce, tag}} <- Vault.encrypt(content, passphrase),
         secret_key <- generate_secret_key(),
         expires_at <- calculate_expires_at(ttl) do
      secret_attrs = %{
        key: secret_key,
        encrypted_content: ciphertext,
        nonce: nonce,
        auth_tag: tag,
        passphrase_hash: Vault.hash_passphrase(passphrase),
        burn_after_reading: Map.get(attrs, :burn_after_reading, true),
        max_views: Map.get(attrs, :max_views, 1),
        expires_at: expires_at,
        metadata: Map.get(attrs, :metadata, %{}),
        recipient: Map.get(attrs, :recipient),
        user_id: Map.get(attrs, :user_id)
      }

      %Secret{}
      |> Secret.changeset(secret_attrs)
      |> Repo.insert()
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Retrieves a secret by its key and optionally decrypts it.

  Returns `{:ok, secret, decrypted_content}` or `{:error, reason}`.

  The secret is marked as viewed and may be burned depending on configuration.
  """
  def get_secret(key, passphrase \\ nil) do
    case Repo.get_by(Secret, key: key) do
      nil ->
        {:error, :not_found}

      secret ->
        cond do
          not Secret.accessible?(secret) ->
            {:error, :not_accessible}

          not Vault.verify_passphrase(passphrase, secret.passphrase_hash) ->
            {:error, :invalid_passphrase}

          true ->
            case decrypt_secret(secret, passphrase) do
              {:ok, content} ->
                {:ok, updated_secret} = increment_views(secret)
                {:ok, updated_secret, content}

              error ->
                error
            end
        end
    end
  end

  @doc """
  Gets secret metadata without decrypting the content.
  """
  def get_secret_metadata(key) do
    case Repo.get_by(Secret, key: key) do
      nil -> {:error, :not_found}
      secret -> {:ok, secret}
    end
  end

  @doc """
  Burns a secret immediately, making it inaccessible.
  """
  def burn_secret(key) do
    case Repo.get_by(Secret, key: key) do
      nil ->
        {:error, :not_found}

      secret ->
        secret
        |> Secret.burn_changeset()
        |> Repo.update()
    end
  end

  @doc """
  Lists all secrets for a given user.
  """
  def list_user_secrets(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    Secret
    |> where([s], s.user_id == ^user_id)
    |> order_by([s], desc: s.inserted_at)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Deletes expired secrets from the database.

  Returns `{:ok, count}` where count is the number of deleted secrets.
  """
  def delete_expired_secrets do
    now = DateTime.utc_now()

    {count, _} =
      Secret
      |> where([s], s.expires_at < ^now)
      |> Repo.delete_all()

    {:ok, count}
  end

  @doc """
  Deletes burned secrets from the database.

  Returns `{:ok, count}` where count is the number of deleted secrets.
  """
  def delete_burned_secrets do
    {count, _} =
      Secret
      |> where([s], s.state == "burned")
      |> Repo.delete_all()

    {:ok, count}
  end

  # Private functions

  defp validate_content_size(content, max_size) do
    if byte_size(content) > max_size do
      {:error, "Content exceeds maximum size of #{max_size} bytes"}
    else
      :ok
    end
  end

  defp decrypt_secret(secret, passphrase) do
    Vault.decrypt(
      secret.encrypted_content,
      secret.nonce,
      secret.auth_tag,
      passphrase
    )
  end

  defp increment_views(secret) do
    secret
    |> Secret.view_changeset()
    |> Repo.update()
  end

  defp generate_secret_key do
    Vault.generate_secret_key(16)
  end

  defp calculate_expires_at(ttl) when is_integer(ttl) do
    DateTime.utc_now()
    |> DateTime.add(ttl, :second)
  end

  defp default_ttl do
    Application.get_env(:onetime, :default_ttl, 604_800)
  end
end

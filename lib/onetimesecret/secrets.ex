defmodule OneTimeSecret.Secrets do
  @moduledoc """
  Context for secret creation, retrieval, and lifecycle management.
  """

  alias OneTimeSecret.Secrets.{Secret, Storage, Encryption}

  @doc """
  Creates a new secret.

  ## Examples

      iex> create_secret(%{value: "sensitive data", ttl: 3600})
      {:ok, %Secret{}}

      iex> create_secret(%{value: "secret", passphrase: "mypass"})
      {:ok, %Secret{}}
  """
  @spec create_secret(map()) :: {:ok, Secret.t()} | {:error, term()}
  def create_secret(attrs \\ %{}) do
    with {:ok, validated} <- Secret.validate(attrs),
         {:ok, encrypted_value} <- encrypt_value(validated),
         secret <- build_secret(validated, encrypted_value),
         {:ok, stored_secret} <- Storage.store(secret) do
      {:ok, stored_secret}
    end
  end

  @doc """
  Retrieves a secret by key, burning it in the process.

  ## Examples

      iex> retrieve_secret("abc123")
      {:ok, %Secret{value: "decrypted content"}}

      iex> retrieve_secret("abc123", passphrase: "mypass")
      {:ok, %Secret{value: "decrypted content"}}
  """
  @spec retrieve_secret(String.t(), keyword()) :: {:ok, Secret.t()} | {:error, term()}
  def retrieve_secret(key, opts \\ []) do
    with {:ok, secret} <- Storage.fetch_and_burn(key),
         {:ok, decrypted_value} <- decrypt_value(secret, opts) do
      Storage.record_view(key, %{retrieved: true})
      {:ok, %{secret | value: decrypted_value}}
    end
  end

  @doc """
  Checks if a secret exists without burning it.

  ## Examples

      iex> secret_exists?("abc123")
      true
  """
  @spec secret_exists?(String.t()) :: boolean()
  def secret_exists?(key) do
    Storage.exists?(key)
  end

  @doc """
  Gets metadata about a secret without revealing its value.

  ## Examples

      iex> get_secret_metadata("abc123")
      {:ok, %{created_at: ~U[2024-01-01 00:00:00Z], ...}}
  """
  @spec get_secret_metadata(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_secret_metadata(key) do
    Storage.get_metadata(key)
  end

  @doc """
  Generates a secure random passphrase.

  ## Examples

      iex> generate_passphrase()
      "aB3dEf9..."
  """
  @spec generate_passphrase(integer()) :: String.t()
  def generate_passphrase(length \\ 32) do
    Encryption.generate_passphrase(length)
  end

  @doc """
  Deletes a secret before it's been viewed.
  """
  @spec burn_secret(String.t()) :: :ok | {:error, term()}
  def burn_secret(key) do
    Storage.delete(key)
  end

  @doc """
  Returns statistics about stored secrets.
  """
  @spec stats() :: {:ok, map()} | {:error, term()}
  def stats do
    with {:ok, count} <- Storage.count() do
      {:ok, %{total_secrets: count}}
    end
  end

  # Private functions

  defp encrypt_value(attrs) do
    passphrase = Map.get(attrs, :passphrase)
    opts = if passphrase, do: [passphrase: passphrase], else: []
    Encryption.encrypt(attrs.value, opts)
  end

  defp decrypt_value(secret, opts) do
    passphrase = Keyword.get(opts, :passphrase)

    decrypt_opts =
      if secret.passphrase_required and passphrase do
        [passphrase: passphrase]
      else
        []
      end

    case Encryption.decrypt(secret.value, decrypt_opts) do
      {:ok, _} = result ->
        result

      {:error, _} = error ->
        if secret.passphrase_required and is_nil(passphrase) do
          {:error, :passphrase_required}
        else
          error
        end
    end
  end

  defp build_secret(attrs, encrypted_value) do
    Secret.new(%{
      value: encrypted_value,
      passphrase_required: Map.has_key?(attrs, :passphrase),
      ttl: Map.get(attrs, :ttl),
      recipient: Map.get(attrs, :recipient),
      metadata: Map.get(attrs, :metadata, %{})
    })
  end
end

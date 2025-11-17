defmodule OneTimeSecret.Secrets.Encryption do
  @moduledoc """
  Handles encryption and decryption of secret values using AES-256-GCM.
  Supports optional passphrase-based encryption using PBKDF2 key derivation.
  """

  @aad "OneTimeSecret"
  @key_iterations 100_000
  @key_length 32
  @salt_length 16
  @iv_length 16

  @doc """
  Encrypts a secret value.

  ## Options
  - `:passphrase` - Optional passphrase for additional encryption layer
  """
  @spec encrypt(String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def encrypt(plaintext, opts \\ []) do
    try do
      passphrase = Keyword.get(opts, :passphrase)

      encrypted =
        if passphrase do
          encrypt_with_passphrase(plaintext, passphrase)
        else
          encrypt_with_key(plaintext, get_master_key())
        end

      {:ok, Base.encode64(encrypted)}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Decrypts a secret value.

  ## Options
  - `:passphrase` - Required if secret was encrypted with passphrase
  """
  @spec decrypt(String.t(), keyword()) :: {:ok, String.t()} | {:error, term()}
  def decrypt(ciphertext, opts \\ []) do
    try do
      passphrase = Keyword.get(opts, :passphrase)
      encrypted = Base.decode64!(ciphertext)

      plaintext =
        if passphrase do
          decrypt_with_passphrase(encrypted, passphrase)
        else
          decrypt_with_key(encrypted, get_master_key())
        end

      {:ok, plaintext}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Generates a secure random passphrase.
  """
  @spec generate_passphrase(integer()) :: String.t()
  def generate_passphrase(length \\ 32) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  # Private functions - AES-GCM encryption

  defp encrypt_with_key(plaintext, key) do
    iv = :crypto.strong_rand_bytes(@iv_length)
    {ciphertext, tag} = :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, plaintext, @aad, true)
    iv <> tag <> ciphertext
  end

  defp decrypt_with_key(<<iv::binary-size(@iv_length), tag::binary-size(16), ciphertext::binary>>, key) do
    :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, ciphertext, @aad, tag, false)
  end

  # Private functions - Passphrase-based encryption

  defp encrypt_with_passphrase(plaintext, passphrase) do
    salt = :crypto.strong_rand_bytes(@salt_length)
    key = derive_key(passphrase, salt)
    encrypted = encrypt_with_key(plaintext, key)
    salt <> encrypted
  end

  defp decrypt_with_passphrase(<<salt::binary-size(@salt_length), encrypted::binary>>, passphrase) do
    key = derive_key(passphrase, salt)
    decrypt_with_key(encrypted, key)
  end

  defp derive_key(passphrase, salt) do
    :crypto.pbkdf2_hmac(:sha256, passphrase, salt, @key_iterations, @key_length)
  end

  defp get_master_key do
    case Application.get_env(:onetimesecret, :encryption_key) do
      nil ->
        raise "Encryption key not configured. Set ENCRYPTION_KEY environment variable."

      key when byte_size(key) < @key_length ->
        # Derive a proper length key from the provided key
        :crypto.hash(:sha256, key)

      key ->
        binary_part(key, 0, @key_length)
    end
  end
end

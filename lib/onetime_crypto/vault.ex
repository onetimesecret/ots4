defmodule OneTime.Vault do
  @moduledoc """
  Encryption and decryption service for secrets using AES-256-GCM.

  This module provides secure encryption for secret data with the following features:
  - AES-256-GCM authenticated encryption
  - Per-secret key derivation using PBKDF2
  - Random nonce generation for each encryption
  - Authentication tags for integrity verification
  """

  @aad "OneTimeSecret"
  @iterations 10_000
  @key_length 32

  @doc """
  Encrypts data with an optional passphrase.

  Returns `{:ok, {ciphertext, nonce, tag}}` or `{:error, reason}`.

  ## Examples

      iex> OneTime.Vault.encrypt("secret data", "passphrase")
      {:ok, {<<...>>, <<...>>, <<...>>}}
  """
  def encrypt(plaintext, passphrase \\ nil) do
    try do
      key = derive_key(passphrase)
      nonce = :crypto.strong_rand_bytes(12)

      {ciphertext, tag} =
        :crypto.crypto_one_time_aead(
          :aes_256_gcm,
          key,
          nonce,
          plaintext,
          @aad,
          true
        )

      {:ok, {ciphertext, nonce, tag}}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Decrypts data with an optional passphrase.

  Returns `{:ok, plaintext}` or `{:error, reason}`.

  ## Examples

      iex> OneTime.Vault.decrypt(ciphertext, nonce, tag, "passphrase")
      {:ok, "secret data"}
  """
  def decrypt(ciphertext, nonce, tag, passphrase \\ nil) do
    try do
      key = derive_key(passphrase)

      case :crypto.crypto_one_time_aead(
             :aes_256_gcm,
             key,
             nonce,
             ciphertext,
             @aad,
             tag,
             false
           ) do
        plaintext when is_binary(plaintext) ->
          {:ok, plaintext}

        :error ->
          {:error, "Decryption failed - invalid passphrase or corrupted data"}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Hashes a passphrase for storage (if passphrase protection is enabled).

  Returns the hashed passphrase using Argon2.
  """
  def hash_passphrase(nil), do: nil

  def hash_passphrase(passphrase) when is_binary(passphrase) do
    Argon2.hash_pwd_salt(passphrase)
  end

  @doc """
  Verifies a passphrase against a stored hash.
  """
  def verify_passphrase(nil, nil), do: true

  def verify_passphrase(passphrase, hash) when is_binary(passphrase) and is_binary(hash) do
    Argon2.verify_pass(passphrase, hash)
  end

  def verify_passphrase(_passphrase, _hash), do: false

  # Private functions

  defp derive_key(nil) do
    # Use the application's master encryption key
    Application.get_env(:onetime, __MODULE__)[:encryption_key]
  end

  defp derive_key(passphrase) when is_binary(passphrase) do
    # Derive a key from the passphrase using PBKDF2
    salt = Application.get_env(:onetime, __MODULE__)[:encryption_key]

    :crypto.pbkdf2_hmac(
      :sha256,
      passphrase,
      salt,
      @iterations,
      @key_length
    )
  end

  @doc """
  Generates a cryptographically secure random string of given length.
  """
  def generate_secret_key(length \\ 32) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64()
    |> binary_part(0, length)
  end
end

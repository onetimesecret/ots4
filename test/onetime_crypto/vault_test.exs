defmodule OneTime.VaultTest do
  use ExUnit.Case, async: true
  alias OneTime.Vault

  describe "encrypt/2 and decrypt/4" do
    test "encrypts and decrypts data without passphrase" do
      plaintext = "sensitive data"

      assert {:ok, {ciphertext, nonce, tag}} = Vault.encrypt(plaintext)
      assert {:ok, decrypted} = Vault.decrypt(ciphertext, nonce, tag)
      assert decrypted == plaintext
    end

    test "encrypts and decrypts data with passphrase" do
      plaintext = "secret message"
      passphrase = "mypassphrase"

      assert {:ok, {ciphertext, nonce, tag}} = Vault.encrypt(plaintext, passphrase)
      assert {:ok, decrypted} = Vault.decrypt(ciphertext, nonce, tag, passphrase)
      assert decrypted == plaintext
    end

    test "fails decryption with wrong passphrase" do
      plaintext = "secret"
      passphrase = "correct"

      {:ok, {ciphertext, nonce, tag}} = Vault.encrypt(plaintext, passphrase)

      assert {:error, _reason} = Vault.decrypt(ciphertext, nonce, tag, "wrong")
    end

    test "generates unique nonces for each encryption" do
      plaintext = "test"

      {:ok, {_, nonce1, _}} = Vault.encrypt(plaintext)
      {:ok, {_, nonce2, _}} = Vault.encrypt(plaintext)

      assert nonce1 != nonce2
    end
  end

  describe "hash_passphrase/1 and verify_passphrase/2" do
    test "hashes and verifies passphrase" do
      passphrase = "testpass123"
      hash = Vault.hash_passphrase(passphrase)

      assert hash != passphrase
      assert Vault.verify_passphrase(passphrase, hash)
      refute Vault.verify_passphrase("wrongpass", hash)
    end

    test "returns nil for nil passphrase" do
      assert Vault.hash_passphrase(nil) == nil
      assert Vault.verify_passphrase(nil, nil)
    end
  end

  describe "generate_secret_key/1" do
    test "generates random keys of specified length" do
      key1 = Vault.generate_secret_key(16)
      key2 = Vault.generate_secret_key(16)

      assert String.length(key1) == 16
      assert String.length(key2) == 16
      assert key1 != key2
    end
  end
end

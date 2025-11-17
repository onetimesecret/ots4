defmodule OneTimeSecret.Secrets.EncryptionTest do
  use ExUnit.Case, async: true

  alias OneTimeSecret.Secrets.Encryption

  describe "encrypt/2 and decrypt/2" do
    test "encrypts and decrypts data successfully" do
      plaintext = "sensitive information"

      assert {:ok, encrypted} = Encryption.encrypt(plaintext)
      assert encrypted != plaintext
      assert {:ok, decrypted} = Encryption.decrypt(encrypted)
      assert decrypted == plaintext
    end

    test "encrypts and decrypts with passphrase" do
      plaintext = "secret data"
      passphrase = "mypassword123"

      assert {:ok, encrypted} = Encryption.encrypt(plaintext, passphrase: passphrase)
      assert {:ok, decrypted} = Encryption.decrypt(encrypted, passphrase: passphrase)
      assert decrypted == plaintext
    end

    test "fails to decrypt with wrong passphrase" do
      plaintext = "secret"
      {:ok, encrypted} = Encryption.encrypt(plaintext, passphrase: "correct")

      assert {:error, _} = Encryption.decrypt(encrypted, passphrase: "wrong")
    end

    test "generates different ciphertext for same plaintext" do
      plaintext = "test"

      {:ok, encrypted1} = Encryption.encrypt(plaintext)
      {:ok, encrypted2} = Encryption.encrypt(plaintext)

      assert encrypted1 != encrypted2
    end
  end

  describe "generate_passphrase/1" do
    test "generates passphrase of correct length" do
      passphrase = Encryption.generate_passphrase(20)

      assert String.length(passphrase) == 20
    end

    test "generates unique passphrases" do
      pass1 = Encryption.generate_passphrase()
      pass2 = Encryption.generate_passphrase()

      assert pass1 != pass2
    end
  end
end

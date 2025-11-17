defmodule OneTimeSecret.SecretsTest do
  use OneTimeSecret.DataCase, async: false

  alias OneTimeSecret.Secrets

  describe "create_secret/1" do
    test "creates a secret with valid attributes" do
      attrs = %{value: "sensitive data", ttl: 3600}

      assert {:ok, secret} = Secrets.create_secret(attrs)
      assert secret.key
      assert secret.ttl == 3600
      refute secret.value  # Value should not be returned
    end

    test "creates a secret with passphrase" do
      attrs = %{value: "secret data", passphrase: "mypassword"}

      assert {:ok, secret} = Secrets.create_secret(attrs)
      assert secret.passphrase_required == true
    end

    test "validates required value" do
      attrs = %{value: ""}

      assert {:error, errors} = Secrets.create_secret(attrs)
      assert Keyword.has_key?(errors, :value)
    end

    test "validates maximum TTL" do
      attrs = %{value: "data", ttl: 999_999_999}

      assert {:error, errors} = Secrets.create_secret(attrs)
      assert Keyword.has_key?(errors, :ttl)
    end
  end

  describe "retrieve_secret/2" do
    test "retrieves and burns a secret" do
      {:ok, secret} = Secrets.create_secret(%{value: "test data"})

      assert {:ok, retrieved} = Secrets.retrieve_secret(secret.key)
      assert retrieved.value == "test data"

      # Second retrieval should fail
      assert {:error, :not_found} = Secrets.retrieve_secret(secret.key)
    end

    test "retrieves secret with passphrase" do
      {:ok, secret} = Secrets.create_secret(%{value: "secret", passphrase: "pass123"})

      # Without passphrase should fail
      assert {:error, _} = Secrets.retrieve_secret(secret.key)

      # With correct passphrase should succeed
      assert {:ok, retrieved} = Secrets.retrieve_secret(secret.key, passphrase: "pass123")
      assert retrieved.value == "secret"
    end

    test "returns error for non-existent secret" do
      assert {:error, :not_found} = Secrets.retrieve_secret("nonexistent")
    end
  end

  describe "secret_exists?/1" do
    test "returns true for existing secret" do
      {:ok, secret} = Secrets.create_secret(%{value: "data"})

      assert Secrets.secret_exists?(secret.key) == true
    end

    test "returns false for non-existent secret" do
      assert Secrets.secret_exists?("nonexistent") == false
    end
  end

  describe "burn_secret/1" do
    test "deletes a secret" do
      {:ok, secret} = Secrets.create_secret(%{value: "data"})

      assert :ok = Secrets.burn_secret(secret.key)
      assert Secrets.secret_exists?(secret.key) == false
    end
  end

  describe "generate_passphrase/1" do
    test "generates a passphrase of specified length" do
      passphrase = Secrets.generate_passphrase(16)

      assert String.length(passphrase) == 16
    end

    test "generates unique passphrases" do
      pass1 = Secrets.generate_passphrase()
      pass2 = Secrets.generate_passphrase()

      assert pass1 != pass2
    end
  end
end

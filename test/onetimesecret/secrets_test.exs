defmodule OneTimeSecret.SecretsTest do
  use ExUnit.Case, async: true

  alias OneTimeSecret.Secrets

  describe "create_secret/1" do
    test "creates a secret with valid attributes" do
      attrs = %{content: "my secret", ttl: 3600}

      assert {:ok, %{secret: secret, metadata: metadata}} = Secrets.create_secret(attrs)
      assert secret.content == "my secret"
      assert secret.ttl == 3600
      assert metadata.secret_key == secret.key
    end

    test "creates a secret with passphrase protection" do
      attrs = %{content: "protected secret", passphrase: "password123", ttl: 3600}

      assert {:ok, %{secret: secret, metadata: _}} = Secrets.create_secret(attrs)
      assert secret.passphrase_hash != nil
    end

    test "sets default TTL when not provided" do
      attrs = %{content: "my secret"}

      assert {:ok, %{secret: secret, metadata: _}} = Secrets.create_secret(attrs)
      assert secret.ttl == 3600
    end
  end

  describe "get_secret/2" do
    test "retrieves a secret by key" do
      {:ok, %{secret: secret, metadata: _}} = Secrets.create_secret(%{content: "test", ttl: 3600})

      assert {:ok, retrieved_secret} = Secrets.get_secret(secret.key)
      assert retrieved_secret.content == "test"
    end

    test "returns error for non-existent secret" do
      assert {:error, :not_found} = Secrets.get_secret("nonexistent")
    end

    test "requires passphrase when set" do
      {:ok, %{secret: secret, metadata: _}} =
        Secrets.create_secret(%{content: "protected", passphrase: "pass123", ttl: 3600})

      assert {:error, :invalid_passphrase} = Secrets.get_secret(secret.key)
      assert {:ok, _} = Secrets.get_secret(secret.key, "pass123")
    end

    test "burns secret after max views reached" do
      {:ok, %{secret: secret, metadata: _}} =
        Secrets.create_secret(%{content: "test", ttl: 3600, max_views: 1})

      assert {:ok, _} = Secrets.get_secret(secret.key)
      assert {:error, :not_found} = Secrets.get_secret(secret.key)
    end
  end

  describe "burn_secret/1" do
    test "immediately deletes a secret" do
      {:ok, %{secret: secret, metadata: _}} = Secrets.create_secret(%{content: "test", ttl: 3600})

      assert :ok = Secrets.burn_secret(secret.key)
      assert {:error, :not_found} = Secrets.get_secret(secret.key)
    end

    test "returns error for non-existent secret" do
      assert {:error, :not_found} = Secrets.burn_secret("nonexistent")
    end
  end
end

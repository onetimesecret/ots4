defmodule OneTime.SecretsTest do
  use OneTime.DataCase
  alias OneTime.Secrets

  describe "create_secret/1" do
    test "creates a secret with valid attributes" do
      attrs = %{
        content: "my secret message",
        ttl: 3600
      }

      assert {:ok, secret} = Secrets.create_secret(attrs)
      assert secret.key != nil
      assert secret.encrypted_content != nil
      assert secret.state == "active"
      assert secret.max_views == 1
    end

    test "creates a secret with passphrase" do
      attrs = %{
        content: "protected secret",
        ttl: 3600,
        passphrase: "mysecretpass"
      }

      assert {:ok, secret} = Secrets.create_secret(attrs)
      assert secret.passphrase_hash != nil
    end

    test "rejects content exceeding max size" do
      large_content = String.duplicate("a", 2_000_000)

      attrs = %{
        content: large_content,
        ttl: 3600
      }

      assert {:error, _reason} = Secrets.create_secret(attrs)
    end
  end

  describe "get_secret/2" do
    test "retrieves and decrypts a secret" do
      {:ok, secret} =
        Secrets.create_secret(%{
          content: "test content",
          ttl: 3600
        })

      assert {:ok, updated_secret, content} = Secrets.get_secret(secret.key)
      assert content == "test content"
      assert updated_secret.views_count == 1
    end

    test "requires correct passphrase" do
      {:ok, secret} =
        Secrets.create_secret(%{
          content: "protected content",
          ttl: 3600,
          passphrase: "correctpass"
        })

      assert {:error, :invalid_passphrase} = Secrets.get_secret(secret.key, "wrongpass")
      assert {:ok, _secret, content} = Secrets.get_secret(secret.key, "correctpass")
      assert content == "protected content"
    end

    test "returns error for non-existent secret" do
      assert {:error, :not_found} = Secrets.get_secret("nonexistent")
    end
  end

  describe "burn_secret/1" do
    test "burns a secret immediately" do
      {:ok, secret} =
        Secrets.create_secret(%{
          content: "burn this",
          ttl: 3600
        })

      assert {:ok, burned_secret} = Secrets.burn_secret(secret.key)
      assert burned_secret.state == "burned"

      assert {:error, :not_accessible} = Secrets.get_secret(secret.key)
    end
  end
end

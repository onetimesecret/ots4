defmodule OneTimeSecret.AccountsTest do
  use ExUnit.Case, async: true

  alias OneTimeSecret.Accounts

  describe "create_user/1" do
    test "creates a user with valid attributes" do
      attrs = %{
        username: "testuser",
        email: "test@example.com",
        password_hash: "hashed_password"
      }

      assert {:ok, user} = Accounts.create_user(attrs)
      assert user.username == "testuser"
      assert user.email == "test@example.com"
    end

    test "requires unique username" do
      attrs = %{username: "duplicate", email: "user1@example.com", password_hash: "hash"}
      {:ok, _} = Accounts.create_user(attrs)

      attrs2 = %{username: "duplicate", email: "user2@example.com", password_hash: "hash"}
      assert {:error, changeset} = Accounts.create_user(attrs2)
      assert changeset.errors[:username]
    end
  end

  describe "create_api_key/2" do
    test "creates an API key for a user" do
      {:ok, user} =
        Accounts.create_user(%{
          username: "apiuser",
          email: "api@example.com",
          password_hash: "hash"
        })

      assert {:ok, api_key, plain_key} = Accounts.create_api_key(user.id, "My API Key")
      assert api_key.label == "My API Key"
      assert is_binary(plain_key)
    end
  end

  describe "authenticate_api_key/1" do
    test "authenticates valid API key" do
      {:ok, user} =
        Accounts.create_user(%{
          username: "authuser",
          email: "auth@example.com",
          password_hash: "hash"
        })

      {:ok, _api_key, plain_key} = Accounts.create_api_key(user.id, "Test Key")

      assert {:ok, authenticated_user} = Accounts.authenticate_api_key(plain_key)
      assert authenticated_user.id == user.id
    end

    test "rejects invalid API key" do
      assert {:error, :invalid_key} = Accounts.authenticate_api_key("invalid_key")
    end
  end
end

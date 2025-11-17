defmodule OneTimeSecret.Accounts do
  @moduledoc """
  The Accounts context.

  Manages user accounts and API keys for authentication.
  """
  import Ecto.Query
  alias OneTimeSecret.Repo
  alias OneTimeSecret.Accounts.{User, APIKey}

  require Logger

  @doc """
  Creates a new user account.
  """
  def create_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets a user by ID.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Gets a user by username.
  """
  def get_user_by_username(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Creates a new API key for a user.
  """
  def create_api_key(user_id, label) do
    {key, hash} = APIKey.generate_key()

    attrs = %{
      label: label,
      key_hash: hash,
      user_id: user_id,
      expires_at: DateTime.utc_now() |> DateTime.add(365, :day)
    }

    case %APIKey{}
         |> APIKey.changeset(attrs)
         |> Repo.insert() do
      {:ok, api_key} ->
        Logger.info("Created API key for user: #{user_id}")
        # Return the plain key only once
        {:ok, api_key, key}

      error ->
        error
    end
  end

  @doc """
  Authenticates a request using an API key.
  """
  def authenticate_api_key(key) do
    hash = APIKey.hash_key(key)

    query =
      from(a in APIKey,
        where: a.key_hash == ^hash and a.is_active == true,
        preload: [:user]
      )

    case Repo.one(query) do
      nil ->
        {:error, :invalid_key}

      api_key ->
        if api_key.expires_at && DateTime.compare(api_key.expires_at, DateTime.utc_now()) == :lt do
          {:error, :expired_key}
        else
          # Update last_used_at
          api_key
          |> Ecto.Changeset.change(%{last_used_at: DateTime.utc_now()})
          |> Repo.update()

          {:ok, api_key.user}
        end
    end
  end

  @doc """
  Revokes an API key.
  """
  def revoke_api_key(api_key_id) do
    case Repo.get(APIKey, api_key_id) do
      nil ->
        {:error, :not_found}

      api_key ->
        api_key
        |> Ecto.Changeset.change(%{is_active: false})
        |> Repo.update()
    end
  end

  @doc """
  Lists all API keys for a user.
  """
  def list_user_api_keys(user_id) do
    query = from(a in APIKey, where: a.user_id == ^user_id, order_by: [desc: a.inserted_at])
    Repo.all(query)
  end
end

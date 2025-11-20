defmodule OneTime.Accounts do
  @moduledoc """
  The Accounts context.

  Handles user registration, authentication, and profile management.
  """

  import Ecto.Query, warn: false
  alias OneTime.Repo
  alias OneTime.Accounts.User
  alias OneTime.Guardian

  @doc """
  Returns the list of users.
  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user by ID.

  Returns `nil` if the user does not exist.
  """
  def get_user(id) do
    Repo.get(User, id)
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by username.
  """
  def get_user_by_username(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Gets a user by API key.
  """
  def get_user_by_api_key(api_key) do
    Repo.get_by(User, api_key: api_key)
  end

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{email: "user@example.com", password: "Password123"})
      {:ok, %User{}}

      iex> create_user(%{email: "invalid"})
      {:error, %Ecto.Changeset{}}
  """
  def create_user(attrs \\ %{}) do
    registration_enabled = Application.get_env(:onetime, :enable_registration, true)

    if registration_enabled do
      %User{}
      |> User.registration_changeset(attrs)
      |> Repo.insert()
    else
      {:error, :registration_disabled}
    end
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Changes a user's password.
  """
  def change_password(%User{} = user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.update_changeset(user, attrs)
  end

  @doc """
  Authenticates a user by email and password.

  Returns `{:ok, user}` if authentication is successful, `{:error, reason}` otherwise.
  """
  def authenticate_user(email, password) do
    user = get_user_by_email(email)

    cond do
      user && user.is_active && User.verify_password(user, password) ->
        {:ok, user}

      user ->
        {:error, :invalid_credentials}

      true ->
        # Perform a dummy password verification to prevent timing attacks
        Argon2.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

  @doc """
  Generates a JWT token for a user.
  """
  def generate_token(%User{} = user) do
    Guardian.encode_and_sign(user)
  end

  @doc """
  Verifies a JWT token.
  """
  def verify_token(token) do
    Guardian.decode_and_verify(token)
  end

  @doc """
  Generates a new API key for a user.
  """
  def generate_api_key(%User{} = user) do
    user
    |> User.api_key_changeset()
    |> Repo.update()
  end

  @doc """
  Revokes a user's API key.
  """
  def revoke_api_key(%User{} = user) do
    user
    |> change(%{api_key: nil})
    |> Repo.update()
  end

  @doc """
  Deactivates a user account.
  """
  def deactivate_user(%User{} = user) do
    user
    |> change(%{is_active: false})
    |> Repo.update()
  end

  @doc """
  Activates a user account.
  """
  def activate_user(%User{} = user) do
    user
    |> change(%{is_active: true})
    |> Repo.update()
  end
end

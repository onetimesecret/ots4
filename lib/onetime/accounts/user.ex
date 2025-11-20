defmodule OneTime.Accounts.User do
  @moduledoc """
  Schema for user accounts.

  Users can create secrets, view their secret history, and manage API keys.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :api_key, :string
    field :is_active, :boolean, default: true
    field :is_admin, :boolean, default: false
    field :metadata, :map, default: %{}

    has_many :secrets, OneTime.Secrets.Secret

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for user registration.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password])
    |> validate_required([:email, :password])
    |> validate_email()
    |> validate_username()
    |> validate_password()
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> hash_password()
  end

  @doc """
  Changeset for updating user profile.
  """
  def update_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :metadata])
    |> validate_email()
    |> validate_username()
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  @doc """
  Changeset for changing password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_password()
    |> hash_password()
  end

  @doc """
  Changeset for generating API key.
  """
  def api_key_changeset(user) do
    api_key = generate_api_key()

    user
    |> change(%{api_key: api_key})
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:email, max: 160)
  end

  defp validate_username(changeset) do
    changeset
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_-]+$/,
      message: "must contain only letters, numbers, underscores, and hyphens"
    )
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 128)
    |> validate_format(:password, ~r/[a-z]/, message: "must contain at least one lowercase letter")
    |> validate_format(:password, ~r/[A-Z]/, message: "must contain at least one uppercase letter")
    |> validate_format(:password, ~r/[0-9]/, message: "must contain at least one number")
  end

  defp hash_password(changeset) do
    case get_change(changeset, :password) do
      nil ->
        changeset

      password ->
        changeset
        |> put_change(:password_hash, Argon2.hash_pwd_salt(password))
        |> delete_change(:password)
    end
  end

  defp generate_api_key do
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64()
  end

  @doc """
  Verifies a password against the stored hash.
  """
  def verify_password(%__MODULE__{password_hash: hash}, password) do
    Argon2.verify_pass(password, hash)
  end

  def verify_password(_user, _password), do: false
end

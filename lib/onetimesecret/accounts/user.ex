defmodule OneTimeSecret.Accounts.User do
  @moduledoc """
  Schema for user accounts.

  Users can create secrets and manage API keys for programmatic access.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :username, :string
    field :email, :string
    field :password_hash, :string
    field :confirmed_at, :utc_datetime
    field :is_admin, :boolean, default: false

    has_many :api_keys, OneTimeSecret.Accounts.APIKey

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for registration.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password_hash])
    |> validate_required([:username, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_length(:username, min: 3, max: 20)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  @doc """
  Creates a changeset for updates.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :confirmed_at, :is_admin])
    |> validate_required([:username, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end
end

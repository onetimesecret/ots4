defmodule OneTimeSecret.Accounts.APIKey do
  @moduledoc """
  Schema for API keys used for programmatic access.

  API keys are hashed before storage and can be rate limited.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "api_keys" do
    field :label, :string
    field :key_hash, :string
    field :last_used_at, :utc_datetime
    field :expires_at, :utc_datetime
    field :is_active, :boolean, default: true

    belongs_to :user, OneTimeSecret.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a new API key.
  """
  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:label, :key_hash, :expires_at, :is_active, :user_id])
    |> validate_required([:label, :key_hash, :user_id])
    |> validate_length(:label, min: 1, max: 100)
    |> foreign_key_constraint(:user_id)
  end

  @doc """
  Generates a new API key.
  Returns a tuple of {key, hash} where key should be shown to the user
  and hash should be stored in the database.
  """
  def generate_key do
    key = :crypto.strong_rand_bytes(32) |> Base.encode64()
    hash = hash_key(key)
    {key, hash}
  end

  @doc """
  Hashes an API key for storage.
  """
  def hash_key(key) do
    :crypto.hash(:sha256, key) |> Base.encode64()
  end

  @doc """
  Verifies an API key against a hash.
  """
  def verify_key(key, hash) do
    hash_key(key) == hash
  end
end

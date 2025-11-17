defmodule OneTimeSecret.Secrets.Secret do
  @moduledoc """
  Schema for storing encrypted secrets.

  Secrets are automatically encrypted using Cloak before being stored in Mnesia.
  Each secret has a unique key, optional passphrase protection, and TTL.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "secrets" do
    field :key, :string
    field :content, OneTimeSecret.Encrypted.Binary
    field :passphrase_hash, :string
    field :ttl, :integer
    field :view_count, :integer, default: 0
    field :max_views, :integer, default: 1
    field :expires_at, :utc_datetime
    field :metadata_key, :string
    field :recipient, :string
    field :created_by, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for a new secret.
  """
  def changeset(secret, attrs) do
    secret
    |> cast(attrs, [
      :key,
      :content,
      :passphrase_hash,
      :ttl,
      :view_count,
      :max_views,
      :expires_at,
      :metadata_key,
      :recipient,
      :created_by
    ])
    |> validate_required([:key, :content, :ttl, :expires_at])
    |> validate_number(:ttl, greater_than: 0, less_than_or_equal: 604_800)
    |> validate_number(:max_views, greater_than: 0, less_than_or_equal: 100)
    |> unique_constraint(:key)
    |> put_expires_at()
  end

  defp put_expires_at(changeset) do
    case get_change(changeset, :ttl) do
      nil ->
        changeset

      ttl ->
        expires_at = DateTime.utc_now() |> DateTime.add(ttl, :second)
        put_change(changeset, :expires_at, expires_at)
    end
  end

  @doc """
  Generates a unique, URL-safe key for a secret.
  """
  def generate_key do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64(padding: false)
  end

  @doc """
  Hashes a passphrase using Argon2.
  """
  def hash_passphrase(passphrase) when is_binary(passphrase) do
    :crypto.hash(:sha256, passphrase)
    |> Base.encode64()
  end

  @doc """
  Verifies a passphrase against a hash.
  """
  def verify_passphrase(passphrase, hash) when is_binary(passphrase) and is_binary(hash) do
    hash_passphrase(passphrase) == hash
  end
end

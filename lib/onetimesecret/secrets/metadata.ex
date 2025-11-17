defmodule OneTimeSecret.Secrets.Metadata do
  @moduledoc """
  Schema for secret metadata.

  Metadata provides information about a secret without revealing its content.
  This is used to check if a secret exists and its properties before viewing.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "metadata" do
    field :key, :string
    field :secret_key, :string
    field :ttl, :integer
    field :view_count, :integer, default: 0
    field :max_views, :integer, default: 1
    field :expires_at, :utc_datetime
    field :received, :boolean, default: false
    field :recipient, :string
    field :passphrase_required, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc """
  Creates a changeset for metadata.
  """
  def changeset(metadata, attrs) do
    metadata
    |> cast(attrs, [
      :key,
      :secret_key,
      :ttl,
      :view_count,
      :max_views,
      :expires_at,
      :received,
      :recipient,
      :passphrase_required
    ])
    |> validate_required([:key, :secret_key, :ttl, :expires_at])
    |> unique_constraint(:key)
  end

  @doc """
  Generates a unique, URL-safe key for metadata.
  """
  def generate_key do
    :crypto.strong_rand_bytes(16)
    |> Base.url_encode64(padding: false)
  end
end

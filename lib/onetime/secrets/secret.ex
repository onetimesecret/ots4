defmodule OneTime.Secrets.Secret do
  @moduledoc """
  Schema for storing encrypted one-time secrets.

  Secrets are stored encrypted and can only be viewed a limited number of times
  before they are automatically destroyed. Each secret has a TTL (time to live)
  after which it expires.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @max_ttl Application.compile_env(:onetime, :max_ttl, 7_776_000)

  schema "secrets" do
    field :key, :string
    field :encrypted_content, :binary
    field :nonce, :binary
    field :auth_tag, :binary
    field :passphrase_hash, :string
    field :burn_after_reading, :boolean, default: true
    field :max_views, :integer, default: 1
    field :views_count, :integer, default: 0
    field :expires_at, :utc_datetime
    field :metadata, :map, default: %{}
    field :recipient, :string
    field :state, :string, default: "active"

    belongs_to :user, OneTime.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset for creating a new secret.
  """
  def changeset(secret, attrs) do
    secret
    |> cast(attrs, [
      :key,
      :encrypted_content,
      :nonce,
      :auth_tag,
      :passphrase_hash,
      :burn_after_reading,
      :max_views,
      :expires_at,
      :metadata,
      :recipient,
      :user_id
    ])
    |> validate_required([:key, :encrypted_content, :nonce, :auth_tag, :expires_at])
    |> validate_number(:max_views, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_inclusion(:state, ["active", "viewed", "burned", "expired"])
    |> unique_constraint(:key)
    |> validate_ttl()
  end

  @doc """
  Changeset for viewing a secret (incrementing view count).
  """
  def view_changeset(secret) do
    views = secret.views_count + 1

    state =
      cond do
        views >= secret.max_views -> "burned"
        true -> "viewed"
      end

    secret
    |> change(%{views_count: views, state: state})
  end

  @doc """
  Changeset for burning a secret immediately.
  """
  def burn_changeset(secret) do
    secret
    |> change(%{state: "burned"})
  end

  defp validate_ttl(changeset) do
    expires_at = get_field(changeset, :expires_at)

    if expires_at do
      now = DateTime.utc_now()
      ttl_seconds = DateTime.diff(expires_at, now)

      cond do
        DateTime.compare(expires_at, now) == :lt ->
          add_error(changeset, :expires_at, "must be in the future")

        ttl_seconds > @max_ttl ->
          add_error(changeset, :expires_at, "TTL exceeds maximum allowed (#{@max_ttl} seconds)")

        true ->
          changeset
      end
    else
      changeset
    end
  end

  @doc """
  Returns true if the secret is still accessible.
  """
  def accessible?(%__MODULE__{} = secret) do
    now = DateTime.utc_now()

    secret.state == "active" and
      secret.views_count < secret.max_views and
      DateTime.compare(secret.expires_at, now) == :gt
  end

  @doc """
  Returns true if the secret has expired.
  """
  def expired?(%__MODULE__{} = secret) do
    now = DateTime.utc_now()
    DateTime.compare(secret.expires_at, now) == :lt
  end
end

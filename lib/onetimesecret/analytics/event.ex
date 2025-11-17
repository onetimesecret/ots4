defmodule OneTimeSecret.Analytics.Event do
  @moduledoc """
  Schema for analytics events.

  Tracks various events like secret creation, viewing, and API usage.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "events" do
    field :event_type, :string
    field :user_id, :binary_id
    field :secret_key, :string
    field :ip_address, :string
    field :user_agent, :string
    field :metadata, :map

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @valid_event_types ~w(secret_created secret_viewed secret_burned api_request)

  @doc """
  Creates a changeset for an event.
  """
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:event_type, :user_id, :secret_key, :ip_address, :user_agent, :metadata])
    |> validate_required([:event_type])
    |> validate_inclusion(:event_type, @valid_event_types)
  end
end

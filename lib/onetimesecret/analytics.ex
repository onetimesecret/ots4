defmodule OneTimeSecret.Analytics do
  @moduledoc """
  The Analytics context.

  Tracks usage metrics for secrets, users, and API requests.
  """
  import Ecto.Query
  alias OneTimeSecret.Repo
  alias OneTimeSecret.Analytics.Event

  require Logger

  @doc """
  Records an analytics event.
  """
  def record_event(type, attrs \\ %{}) do
    %Event{}
    |> Event.changeset(Map.put(attrs, :event_type, type))
    |> Repo.insert()
  end

  @doc """
  Gets usage statistics for a given time period.
  """
  def get_statistics(from_date, to_date) do
    query =
      from(e in Event,
        where: e.inserted_at >= ^from_date and e.inserted_at <= ^to_date,
        group_by: e.event_type,
        select: {e.event_type, count(e.id)}
      )

    Repo.all(query)
    |> Enum.into(%{})
  end

  @doc """
  Gets the total number of secrets created.
  """
  def total_secrets_created do
    query = from(e in Event, where: e.event_type == "secret_created", select: count(e.id))
    Repo.one(query) || 0
  end

  @doc """
  Gets the total number of secrets viewed.
  """
  def total_secrets_viewed do
    query = from(e in Event, where: e.event_type == "secret_viewed", select: count(e.id))
    Repo.one(query) || 0
  end
end

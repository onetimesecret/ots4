defmodule OneTime.Secrets.Janitor do
  @moduledoc """
  GenServer that periodically cleans up expired and burned secrets.

  Runs cleanup tasks every hour by default.
  """
  use GenServer
  require Logger

  alias OneTime.Secrets

  @cleanup_interval :timer.hours(1)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    Logger.info("Starting secret cleanup...")

    case Secrets.delete_expired_secrets() do
      {:ok, count} ->
        Logger.info("Deleted #{count} expired secrets")

      {:error, reason} ->
        Logger.error("Failed to delete expired secrets: #{inspect(reason)}")
    end

    case Secrets.delete_burned_secrets() do
      {:ok, count} ->
        Logger.info("Deleted #{count} burned secrets")

      {:error, reason} ->
        Logger.error("Failed to delete burned secrets: #{inspect(reason)}")
    end

    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end

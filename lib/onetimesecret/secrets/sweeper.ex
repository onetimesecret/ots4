defmodule OneTimeSecret.Secrets.Sweeper do
  @moduledoc """
  Background worker that periodically cleans up expired secrets.

  Runs every 5 minutes to remove secrets that have passed their TTL.
  """
  use GenServer
  require Logger

  alias OneTimeSecret.Secrets

  @cleanup_interval :timer.minutes(5)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Schedule the first cleanup
    schedule_cleanup()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    Logger.debug("Running secret cleanup...")

    case Secrets.delete_expired_secrets() do
      {:ok, count} when count > 0 ->
        Logger.info("Cleaned up #{count} expired secrets")

      {:ok, 0} ->
        Logger.debug("No expired secrets to clean up")

      {:error, reason} ->
        Logger.error("Failed to clean up expired secrets: #{inspect(reason)}")
    end

    schedule_cleanup()
    {:noreply, state}
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end

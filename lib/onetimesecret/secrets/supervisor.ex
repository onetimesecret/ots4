defmodule OneTimeSecret.Secrets.Supervisor do
  @moduledoc """
  Supervisor for secret management processes.
  Currently manages cleanup workers and future expiration managers.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Future: Add cleanup worker for expired secrets
      # {OneTimeSecret.Secrets.CleanupWorker, []},
      # Future: Add expiration manager for notifications
      # {OneTimeSecret.Secrets.ExpirationManager, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

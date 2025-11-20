defmodule OneTime.Application do
  @moduledoc """
  The OneTime Application Service.

  This module starts the supervision tree for the OneTimeSecret application,
  managing all processes including the database connection pool, PubSub system,
  and the Phoenix endpoint.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      OneTimeWeb.Telemetry,
      # Start the Ecto repository
      OneTime.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: OneTime.PubSub},
      # Start Finch for HTTP requests
      {Finch, name: OneTime.Finch},
      # Start the Endpoint (http/https)
      OneTimeWeb.Endpoint,
      # Start the Secret cleanup scheduler
      OneTime.Secrets.Janitor,
      # Start a worker by calling: OneTime.Worker.start_link(arg)
      # {OneTime.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OneTime.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OneTimeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

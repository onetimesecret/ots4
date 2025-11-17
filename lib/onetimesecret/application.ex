defmodule OneTimeSecret.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Telemetry supervisor
      OneTimeSecretWeb.Telemetry,
      # PubSub system
      {Phoenix.PubSub, name: OneTimeSecret.PubSub},
      # Redis connection pool
      OneTimeSecret.Redis.Supervisor,
      # Secrets management supervisor
      OneTimeSecret.Secrets.Supervisor,
      # Start the endpoint when the application starts
      OneTimeSecretWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OneTimeSecret.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OneTimeSecretWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

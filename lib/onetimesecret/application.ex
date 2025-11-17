defmodule OneTimeSecret.Application do
  @moduledoc """
  The OneTimeSecret application.

  This module starts and supervises the main components of the application,
  including the endpoint, PubSub, and background workers.
  """
  use Application

  @impl true
  def start(_type, _args) do
    # Ensure Mnesia is started and create schema if needed
    setup_mnesia()

    children = [
      # Start the Telemetry supervisor
      OneTimeSecretWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: OneTimeSecret.PubSub},
      # Start the Mnesia repo
      OneTimeSecret.Repo,
      # Start the Cloak vault for encryption
      OneTimeSecret.Vault,
      # Start the ETS cache manager
      OneTimeSecret.Cache,
      # Start the Endpoint (http/https)
      OneTimeSecretWeb.Endpoint,
      # Start the secret cleanup worker
      OneTimeSecret.Secrets.Sweeper,
      # Start rate limiting
      {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 2, cleanup_interval_ms: 60_000 * 10]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
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

  defp setup_mnesia do
    # Ensure Mnesia directory exists
    mnesia_dir = Application.get_env(:mnesia, :dir, ~c"priv/mnesia/dev")
    mnesia_dir |> List.to_string() |> Path.dirname() |> File.mkdir_p!()

    # Start Mnesia
    :mnesia.start()

    # Create schema if it doesn't exist
    case :mnesia.create_schema([node()]) do
      :ok -> :ok
      {:error, {_, {:already_exists, _}}} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end

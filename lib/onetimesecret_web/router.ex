defmodule OneTimeSecretWeb.Router do
  use OneTimeSecretWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OneTimeSecretWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug OneTimeSecretWeb.Plugs.RateLimiter
  end

  # Browser routes
  scope "/", OneTimeSecretWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/secret/:key", SecretController, :show
    post "/secret", SecretController, :create
    get "/share/:key", ShareController, :show
  end

  # API routes
  scope "/api", OneTimeSecretWeb.API do
    pipe_through :api

    post "/secret", SecretController, :create
    get "/secret/:key", SecretController, :show
    post "/secret/:key/burn", SecretController, :burn
    get "/secret/:key/metadata", SecretController, :metadata
    get "/stats", StatsController, :index
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:onetimesecret, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OneTimeSecretWeb.Telemetry
    end
  end

  # Health check endpoint
  scope "/health" do
    get "/", OneTimeSecretWeb.HealthController, :index
  end
end

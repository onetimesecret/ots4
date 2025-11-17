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
    plug OneTimeSecretWeb.Plugs.APIAuth
    plug OneTimeSecretWeb.Plugs.RateLimit
  end

  # Public routes
  scope "/", OneTimeSecretWeb do
    pipe_through :browser

    live "/", HomeLive, :index
    live "/secret/:key", SecretLive, :show
    live "/create", CreateSecretLive, :new
  end

  # API v2 routes
  scope "/api/v2", OneTimeSecretWeb.API.V2, as: :api_v2 do
    pipe_through :api

    post "/share", SecretController, :create
    get "/secret/:key", SecretController, :show
    post "/secret/:key/burn", SecretController, :burn
    get "/secret/:key/metadata", SecretController, :metadata

    # Account management
    post "/account/register", AccountController, :register
    post "/account/apikey", APIKeyController, :create
    get "/account/apikeys", APIKeyController, :index
    delete "/account/apikey/:id", APIKeyController, :delete
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:onetimesecret, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OneTimeSecretWeb.Telemetry
    end
  end
end

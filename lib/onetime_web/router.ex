defmodule OneTimeWeb.Router do
  use OneTimeWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OneTimeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Hammer.Plug,
      rate_limit: {"browser", 60_000, 100},
      by: :ip
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Hammer.Plug,
      rate_limit: {"api", 60_000, 60},
      by: :ip
  end

  pipeline :api_auth do
    plug OneTimeWeb.Plugs.APIAuth
  end

  # Public routes
  scope "/", OneTimeWeb do
    pipe_through :browser

    live "/", HomeLive, :index
    live "/secret/new", SecretLive.New, :new
    live "/secret/:key", SecretLive.Show, :show
    live "/about", AboutLive, :index
  end

  # Authenticated routes
  scope "/", OneTimeWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/dashboard", DashboardLive, :index
    live "/secrets", SecretLive.Index, :index
    live "/profile", ProfileLive, :index
  end

  # Authentication routes
  scope "/auth", OneTimeWeb do
    pipe_through :browser

    live "/login", AuthLive.Login, :login
    live "/register", AuthLive.Register, :register
    get "/logout", AuthController, :logout
  end

  # API routes - v1
  scope "/api/v1", OneTimeWeb.API.V1, as: :api_v1 do
    pipe_through :api

    post "/secrets", SecretController, :create
    get "/secrets/:key/metadata", SecretController, :metadata
    post "/secrets/:key", SecretController, :show
    delete "/secrets/:key", SecretController, :burn
  end

  # API routes - authenticated
  scope "/api/v1", OneTimeWeb.API.V1, as: :api_v1 do
    pipe_through [:api, :api_auth]

    get "/secrets", SecretController, :index
    post "/auth/token", AuthController, :generate_token
  end

  # GraphQL API
  scope "/api" do
    pipe_through :api

    forward "/graphql", Absinthe.Plug,
      schema: OneTimeWeb.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: OneTimeWeb.Schema,
      interface: :playground
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:onetime, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OneTimeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  # Health check endpoint
  scope "/health", OneTimeWeb do
    pipe_through :api

    get "/", HealthController, :check
  end
end

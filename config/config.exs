import Config

# General application configuration
config :onetime,
  ecto_repos: [OneTime.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :onetime, OneTimeWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: OneTimeWeb.ErrorHTML, json: OneTimeWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: OneTime.PubSub,
  live_view: [signing_salt: "onetime_secret"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  onetime: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  onetime: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Guardian configuration
config :onetime, OneTime.Guardian,
  issuer: "onetime",
  ttl: {30, :days},
  verify_issuer: true,
  serializer: OneTime.Guardian.Serializer

# Argon2 configuration
config :argon2_elixir,
  t_cost: 8,
  m_cost: 17,
  parallelism: 2

# Rate limiting configuration
config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

# Import environment specific config
import_config "#{config_env()}.exs"

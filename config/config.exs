import Config

# Configure the application
config :onetimesecret,
  namespace: OneTimeSecret,
  ecto_repos: [OneTimeSecret.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :onetimesecret, OneTimeSecretWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: OneTimeSecretWeb.ErrorHTML, json: OneTimeSecretWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: OneTimeSecret.PubSub,
  live_view: [signing_salt: "changeme"]

# Configure esbuild
config :esbuild,
  version: "0.17.11",
  onetimesecret: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind
config :tailwind,
  version: "3.4.0",
  onetimesecret: [
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

# Configure Mnesia
config :mnesia,
  dir: ~c"priv/mnesia/#{config_env()}"

# Configure Ecto to use Mnesia adapter
config :onetimesecret, OneTimeSecret.Repo,
  adapter: Ecto.Adapters.Mnesia

# Configure Cloak for encryption
config :onetimesecret, OneTimeSecret.Vault,
  ciphers: [
    default: {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: :base64.decode("CHANGE_ME_IN_RUNTIME")}
  ]

# Import environment specific config
import_config "#{config_env()}.exs"

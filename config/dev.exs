import Config

# For development, we disable any cache and enable
# debugging and code reloading.
config :onetimesecret, OneTimeSecretWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "onetimesecret_dev_secret_key_base_change_in_production_please_use_a_long_random_string",
  watchers: []

# Enable dev routes for dashboard and mailbox
config :onetimesecret, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Redis configuration for development
config :onetimesecret, :redis,
  host: "localhost",
  port: 6379,
  database: 0

config :onetimesecret, :redis_pool_size, 5

# Secret settings for development
config :onetimesecret,
  default_ttl: 86400,
  # 1 day
  max_ttl: 604_800,
  # 7 days
  max_secret_size: 1_000_000,
  # 1MB
  encryption_key: "onetimesecret_dev_encryption_key_32"

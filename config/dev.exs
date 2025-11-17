import Config

# For development, we disable any cache and enable
# debugging and code reloading.
config :onetimesecret, OneTimeSecretWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "dev_secret_key_base_at_least_64_bytes_long_change_in_production_please",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:onetimesecret, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:onetimesecret, ~w(--watch)]}
  ]

# Watch static and templates for browser reloading.
config :onetimesecret, OneTimeSecretWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/onetimesecret_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

# Enable dev routes for dashboard and mailbox
config :onetimesecret, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Development encryption key (DO NOT use in production)
config :onetimesecret, OneTimeSecret.Vault,
  ciphers: [
    default: {Cloak.Ciphers.AES.GCM,
      tag: "AES.GCM.V1",
      key: Base.decode64!("3Jnb0hZiHIzHTOih7t2cNWoWJNJdIbmS7eIhqQBQvmY=")}
  ]

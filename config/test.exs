import Config

# Configure your database
config :onetime, OneTime.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "onetime_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :onetime, OneTimeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test_secret_key_base_for_testing_only_not_for_production",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Reduce password hashing rounds for faster tests
config :argon2_elixir,
  t_cost: 1,
  m_cost: 8

# Guardian test secret
config :onetime, OneTime.Guardian,
  secret_key: "test_guardian_secret_key_for_testing"

# Encryption key for testing
config :onetime, OneTime.Vault,
  encryption_key: "test_encryption_key_32_bytes!!"

# Wallaby configuration for E2E tests
config :wallaby,
  driver: Wallaby.Chrome,
  hackney_options: [timeout: :infinity, recv_timeout: :infinity],
  screenshot_on_failure: true

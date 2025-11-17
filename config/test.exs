import Config

# We don't run a server during test
config :onetimesecret, OneTimeSecretWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "onetimesecret_test_secret_key_base_change_in_production_please_use_a_long_random_string",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Redis configuration for test
config :onetimesecret, :redis,
  host: "localhost",
  port: 6379,
  database: 1

config :onetimesecret, :redis_pool_size, 2

# Secret settings for test
config :onetimesecret,
  default_ttl: 3600,
  max_ttl: 86400,
  max_secret_size: 100_000,
  encryption_key: "onetimesecret_test_encryption_key32"

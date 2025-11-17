import Config

# Runtime production configuration
if config_env() == :prod do
  # Redis configuration from environment
  config :onetimesecret, :redis,
    host: System.get_env("REDIS_HOST") || "localhost",
    port: String.to_integer(System.get_env("REDIS_PORT") || "6379"),
    password: System.get_env("REDIS_PASSWORD"),
    ssl: System.get_env("REDIS_SSL") == "true",
    database: String.to_integer(System.get_env("REDIS_DATABASE") || "0")

  config :onetimesecret, :redis_pool_size,
         String.to_integer(System.get_env("REDIS_POOL_SIZE") || "10")

  # Secret settings from environment
  config :onetimesecret,
    default_ttl: String.to_integer(System.get_env("DEFAULT_TTL") || "86400"),
    max_ttl: String.to_integer(System.get_env("MAX_TTL") || "604800"),
    max_secret_size: String.to_integer(System.get_env("MAX_SECRET_SIZE") || "1000000"),
    encryption_key: System.fetch_env!("ENCRYPTION_KEY")

  # Endpoint configuration
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :onetimesecret, OneTimeSecretWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # SSL configuration (optional)
  if System.get_env("SSL_KEY_PATH") && System.get_env("SSL_CERT_PATH") do
    config :onetimesecret, OneTimeSecretWeb.Endpoint,
      https: [
        port: 443,
        cipher_suite: :strong,
        keyfile: System.get_env("SSL_KEY_PATH"),
        certfile: System.get_env("SSL_CERT_PATH")
      ]
  end
end

import Config

# Runtime configuration for production
if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  # Build SSL options conditionally
  ssl_opts = [
    verify: :verify_peer,
    server_name_indication: to_charlist(System.get_env("DATABASE_HOSTNAME") || "localhost"),
    customize_hostname_check: [
      match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
    ]
  ]

  # Add cacertfile only if provided
  ssl_opts =
    if cacertfile = System.get_env("DATABASE_CA_CERT_PATH") do
      Keyword.put(ssl_opts, :cacertfile, cacertfile)
    else
      ssl_opts
    end

  config :onetime, OneTime.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6,
    ssl: true,
    ssl_opts: ssl_opts

  # The secret key base is used to sign/encrypt cookies and other secrets.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PHX_PORT") || "4000")

  config :onetime, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :onetime, OneTimeWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    server: true

  # Guardian production configuration
  guardian_secret =
    System.get_env("GUARDIAN_SECRET") ||
      raise """
      environment variable GUARDIAN_SECRET is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :onetime, OneTime.Guardian,
    secret_key: guardian_secret

  # Encryption configuration
  encryption_key =
    System.get_env("ENCRYPTION_KEY") ||
      raise """
      environment variable ENCRYPTION_KEY is missing.
      Must be exactly 32 bytes. Generate with: mix phx.gen.secret 32
      """

  if byte_size(encryption_key) != 32 do
    raise "ENCRYPTION_KEY must be exactly 32 bytes"
  end

  config :onetime, OneTime.Vault,
    encryption_key: encryption_key

  # Email configuration
  if smtp_host = System.get_env("SMTP_HOST") do
    config :onetime, OneTime.Mailer,
      adapter: Swoosh.Adapters.SMTP,
      relay: smtp_host,
      port: String.to_integer(System.get_env("SMTP_PORT") || "587"),
      username: System.get_env("SMTP_USER"),
      password: System.get_env("SMTP_PASS"),
      ssl: System.get_env("SMTP_SSL") in ~w(true 1),
      tls: :always,
      auth: :always,
      retries: 2
  end

  # Rate limiting with Redis (optional)
  if redis_url = System.get_env("REDIS_URL") do
    config :hammer,
      backend: {Hammer.Backend.Redis, [expiry_ms: 60_000 * 60 * 4, redis_url: redis_url]}
  end

  # Application configuration
  config :onetime,
    max_secret_size: String.to_integer(System.get_env("MAX_SECRET_SIZE") || "1048576"),
    default_ttl: String.to_integer(System.get_env("DEFAULT_TTL") || "604800"),
    max_ttl: String.to_integer(System.get_env("MAX_TTL") || "7776000"),
    enable_registration: System.get_env("ENABLE_REGISTRATION") in ~w(true 1),
    rate_limit_per_minute: String.to_integer(System.get_env("RATE_LIMIT_PER_MINUTE") || "60")
end

import Config

# Runtime configuration for production
if config_env() == :prod do
  # Read encryption key from environment
  encryption_key =
    System.get_env("ENCRYPTION_KEY") ||
      raise """
      environment variable ENCRYPTION_KEY is missing.
      Generate a secure key with: mix phx.gen.secret 32
      Then base64 encode it for use here.
      """

  config :onetimesecret, OneTimeSecret.Vault,
    ciphers: [
      default: {
        Cloak.Ciphers.AES.GCM,
        tag: "AES.GCM.V1",
        key: Base.decode64!(encryption_key)
      }
    ]

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
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # Configure Mnesia for production
  mnesia_dir = System.get_env("MNESIA_DIR") || "priv/mnesia/prod"
  config :mnesia, dir: String.to_charlist(mnesia_dir)
end

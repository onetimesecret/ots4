defmodule OneTimeWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :onetime

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_onetime_key",
    signing_salt: "onetime_signing",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: false

  socket "/phoenix/live_reload/socket", Phoenix.LiveReload.Socket
  plug Phoenix.LiveReload
  plug Phoenix.CodeReloader

  # Serve at "/" the static files from "priv/static" directory.
  plug Plug.Static,
    at: "/",
    from: :onetime,
    gzip: false,
    only: OneTimeWeb.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReload.Socket
    plug Phoenix.LiveReload
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :onetime
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  # Security headers
  plug :put_secure_browser_headers

  plug CORSPlug,
    origin: ["http://localhost:4000"],
    max_age: 86400,
    methods: ["GET", "POST"]

  plug OneTimeWeb.Router

  defp put_secure_browser_headers(conn, _opts) do
    conn
    |> Plug.Conn.put_resp_header("x-frame-options", "DENY")
    |> Plug.Conn.put_resp_header("x-content-type-options", "nosniff")
    |> Plug.Conn.put_resp_header("x-xss-protection", "1; mode=block")
    |> Plug.Conn.put_resp_header(
      "content-security-policy",
      "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"
    )
    |> Plug.Conn.put_resp_header("referrer-policy", "strict-origin-when-cross-origin")
  end
end

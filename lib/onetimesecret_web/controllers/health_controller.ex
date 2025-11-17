defmodule OneTimeSecretWeb.HealthController do
  use OneTimeSecretWeb, :controller

  alias OneTimeSecret.Redis

  def index(conn, _params) do
    redis_status =
      case Redis.ping() do
        :ok -> "healthy"
        _ -> "unhealthy"
      end

    status = if redis_status == "healthy", do: :ok, else: :service_unavailable

    conn
    |> put_status(status)
    |> json(%{
      status: if(status == :ok, do: "healthy", else: "unhealthy"),
      redis: redis_status,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end
end

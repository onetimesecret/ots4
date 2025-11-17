defmodule OneTimeSecretWeb.Plugs.RateLimit do
  @moduledoc """
  Plug for rate limiting API requests using Hammer.

  Rate limits are applied per IP address or per API key.
  """
  import Plug.Conn

  @default_limit 100
  @default_period 60_000

  def init(opts) do
    %{
      limit: Keyword.get(opts, :limit, @default_limit),
      period: Keyword.get(opts, :period, @default_period)
    }
  end

  def call(conn, opts) do
    identifier = get_identifier(conn)
    limit = opts[:limit] || @default_limit
    period = opts[:period] || @default_period

    case Hammer.check_rate(identifier, period, limit) do
      {:allow, _count} ->
        conn

      {:deny, _limit} ->
        conn
        |> put_status(:too_many_requests)
        |> Phoenix.Controller.json(%{
          error: "Rate limit exceeded",
          retry_after: period / 1000
        })
        |> halt()
    end
  end

  defp get_identifier(conn) do
    case conn.assigns[:current_user] do
      nil ->
        # Use IP address for unauthenticated requests
        ip = get_ip(conn)
        "ip:#{ip}"

      user ->
        # Use user ID for authenticated requests
        "user:#{user.id}"
    end
  end

  defp get_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> ip
      [] -> to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end
end

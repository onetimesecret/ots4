defmodule OneTimeSecretWeb.Plugs.RateLimiter do
  @moduledoc """
  Rate limiting plug using Redis for distributed rate limiting.
  Implements sliding window rate limiting per IP address.
  """

  import Plug.Conn
  alias OneTimeSecret.Redis

  @default_limit 100
  @default_window 60

  def init(opts) do
    %{
      limit: Keyword.get(opts, :limit, @default_limit),
      window: Keyword.get(opts, :window, @default_window)
    }
  end

  def call(conn, opts) do
    ip = get_client_ip(conn)
    endpoint = conn.request_path
    key = "rate:#{ip}:#{endpoint}"

    case check_rate_limit(key, opts.limit, opts.window) do
      {:ok, remaining} ->
        conn
        |> put_resp_header("x-ratelimit-limit", to_string(opts.limit))
        |> put_resp_header("x-ratelimit-remaining", to_string(remaining))

      {:error, :rate_limited} ->
        conn
        |> put_resp_header("x-ratelimit-limit", to_string(opts.limit))
        |> put_resp_header("x-ratelimit-remaining", "0")
        |> send_resp(429, Jason.encode!(%{error: "Rate limit exceeded"}))
        |> halt()
    end
  end

  defp check_rate_limit(key, limit, window) do
    now = System.system_time(:second)

    commands = [
      ["INCR", key],
      ["EXPIRE", key, window]
    ]

    case Redis.pipeline(commands) do
      {:ok, [count, _]} when count <= limit ->
        {:ok, limit - count}

      {:ok, [count, _]} when count > limit ->
        {:error, :rate_limited}

      _ ->
        # On error, allow the request (fail open)
        {:ok, limit}
    end
  end

  defp get_client_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> ip
      [] -> to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end
end

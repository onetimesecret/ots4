defmodule OneTimeSecretWeb.API.SecretController do
  use OneTimeSecretWeb, :controller

  alias OneTimeSecret.Secrets

  action_fallback OneTimeSecretWeb.API.FallbackController

  @doc """
  Creates a new secret via API.

  ## Request body
  - `value` (required): The secret content
  - `ttl` (optional): Time to live in seconds
  - `passphrase` (optional): Additional passphrase protection
  - `recipient` (optional): Intended recipient identifier
  """
  def create(conn, params) do
    attrs = %{
      value: params["value"],
      ttl: parse_ttl(params["ttl"]),
      passphrase: params["passphrase"],
      recipient: params["recipient"],
      metadata: %{
        ip: get_client_ip(conn),
        user_agent: get_user_agent(conn)
      }
    }

    with {:ok, secret} <- Secrets.create_secret(attrs) do
      conn
      |> put_status(:created)
      |> json(%{
        status: "success",
        data: %{
          key: secret.key,
          ttl: secret.ttl,
          expires_at: DateTime.to_iso8601(secret.expires_at),
          passphrase_required: secret.passphrase_required,
          share_url: build_share_url(conn, secret.key)
        }
      })
    end
  end

  @doc """
  Retrieves (and burns) a secret via API.
  """
  def show(conn, %{"key" => key} = params) do
    passphrase = params["passphrase"]
    opts = if passphrase, do: [passphrase: passphrase], else: []

    with {:ok, secret} <- Secrets.retrieve_secret(key, opts) do
      json(conn, %{
        status: "success",
        data: %{
          value: secret.value,
          created_at: DateTime.to_iso8601(secret.created_at),
          recipient: secret.recipient
        }
      })
    end
  end

  @doc """
  Gets metadata about a secret without burning it.
  """
  def metadata(conn, %{"key" => key}) do
    with {:ok, metadata} <- Secrets.get_secret_metadata(key) do
      json(conn, %{
        status: "success",
        data: metadata
      })
    end
  end

  @doc """
  Manually burns a secret before retrieval.
  """
  def burn(conn, %{"key" => key}) do
    case Secrets.burn_secret(key) do
      :ok ->
        json(conn, %{
          status: "success",
          message: "Secret burned successfully"
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          status: "error",
          message: "Failed to burn secret: #{inspect(reason)}"
        })
    end
  end

  # Private helpers

  defp parse_ttl(nil), do: nil
  defp parse_ttl(ttl) when is_integer(ttl), do: ttl
  defp parse_ttl(ttl) when is_binary(ttl), do: String.to_integer(ttl)

  defp get_client_ip(conn) do
    case Plug.Conn.get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> ip
      [] -> to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end

  defp get_user_agent(conn) do
    case Plug.Conn.get_req_header(conn, "user-agent") do
      [ua | _] -> ua
      [] -> "unknown"
    end
  end

  defp build_share_url(conn, key) do
    url(conn) <> "/secret/#{key}"
  end
end

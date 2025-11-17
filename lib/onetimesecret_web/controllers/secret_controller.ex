defmodule OneTimeSecretWeb.SecretController do
  use OneTimeSecretWeb, :controller

  alias OneTimeSecret.Secrets

  def create(conn, %{"secret" => secret_params}) do
    attrs = %{
      value: secret_params["value"],
      ttl: parse_ttl(secret_params["ttl"]),
      passphrase: secret_params["passphrase"],
      recipient: secret_params["recipient"],
      metadata: %{
        ip: get_client_ip(conn),
        user_agent: get_user_agent(conn)
      }
    }

    case Secrets.create_secret(attrs) do
      {:ok, secret} ->
        conn
        |> put_flash(:info, "Secret created successfully!")
        |> redirect(to: "/share/#{secret.key}")

      {:error, errors} ->
        conn
        |> put_flash(:error, format_errors(errors))
        |> redirect(to: "/")
    end
  end

  def show(conn, %{"key" => key} = params) do
    passphrase = params["passphrase"]
    opts = if passphrase, do: [passphrase: passphrase], else: []

    case Secrets.retrieve_secret(key, opts) do
      {:ok, secret} ->
        render(conn, :show, secret: secret)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Secret not found or already viewed")
        |> redirect(to: "/")

      {:error, :passphrase_required} ->
        render(conn, :passphrase, key: key)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Error retrieving secret: #{inspect(reason)}")
        |> redirect(to: "/")
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

  defp format_errors(errors) when is_list(errors) do
    errors
    |> Enum.map(fn {field, message} -> "#{field}: #{message}" end)
    |> Enum.join(", ")
  end

  defp format_errors(error), do: inspect(error)
end

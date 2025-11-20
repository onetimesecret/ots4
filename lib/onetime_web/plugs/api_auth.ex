defmodule OneTimeWeb.Plugs.APIAuth do
  @moduledoc """
  Plug for API authentication using API keys or JWT tokens.
  """
  import Plug.Conn
  import Phoenix.Controller
  alias OneTime.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    with {:ok, token} <- extract_token(conn),
         {:ok, user} <- authenticate(token) do
      assign(conn, :current_user, user)
    else
      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
        |> halt()
    end
  end

  defp extract_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:ok, {:jwt, token}}
      ["ApiKey " <> api_key] -> {:ok, {:api_key, api_key}}
      _ -> {:error, "Missing or invalid authorization header"}
    end
  end

  defp authenticate({:api_key, api_key}) do
    case Accounts.get_user_by_api_key(api_key) do
      nil -> {:error, "Invalid API key"}
      user -> {:ok, user}
    end
  end

  defp authenticate({:jwt, token}) do
    case OneTime.Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        case OneTime.Guardian.resource_from_claims(claims) do
          {:ok, user} -> {:ok, user}
          {:error, _} -> {:error, "Invalid token"}
        end

      {:error, _} ->
        {:error, "Invalid token"}
    end
  end
end

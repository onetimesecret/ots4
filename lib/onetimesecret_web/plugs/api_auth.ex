defmodule OneTimeSecretWeb.Plugs.APIAuth do
  @moduledoc """
  Plug for authenticating API requests using API keys.

  Checks for Authorization header with format: "Bearer <api_key>"
  """
  import Plug.Conn
  alias OneTimeSecret.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    with ["Bearer " <> api_key] <- get_req_header(conn, "authorization"),
         {:ok, user} <- Accounts.authenticate_api_key(api_key) do
      conn
      |> assign(:current_user, user)
      |> assign(:authenticated, true)
    else
      _ ->
        # API key is optional for some endpoints
        conn
        |> assign(:current_user, nil)
        |> assign(:authenticated, false)
    end
  end

  @doc """
  Ensures the request is authenticated.
  Returns 401 if not authenticated.
  """
  def require_auth(conn, _opts) do
    if conn.assigns[:authenticated] do
      conn
    else
      conn
      |> put_status(:unauthorized)
      |> Phoenix.Controller.json(%{error: "Unauthorized"})
      |> halt()
    end
  end
end

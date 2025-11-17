defmodule OneTimeSecretWeb.API.V2.APIKeyController do
  use OneTimeSecretWeb, :controller

  alias OneTimeSecret.Accounts

  plug OneTimeSecretWeb.Plugs.APIAuth, :require_auth

  action_fallback OneTimeSecretWeb.FallbackController

  @doc """
  Create a new API key for the authenticated user.

  POST /api/v2/account/apikey
  Body: {
    "label": "My API Key"
  }
  """
  def create(conn, %{"label" => label}) do
    user = conn.assigns.current_user

    case Accounts.create_api_key(user.id, label) do
      {:ok, api_key, plain_key} ->
        conn
        |> put_status(:created)
        |> json(%{
          id: api_key.id,
          label: api_key.label,
          key: plain_key,
          expires_at: api_key.expires_at,
          message: "Store this key securely. It will not be shown again."
        })

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  List all API keys for the authenticated user.

  GET /api/v2/account/apikeys
  """
  def index(conn, _params) do
    user = conn.assigns.current_user
    api_keys = Accounts.list_user_api_keys(user.id)

    json(conn, %{
      api_keys:
        Enum.map(api_keys, fn key ->
          %{
            id: key.id,
            label: key.label,
            last_used_at: key.last_used_at,
            expires_at: key.expires_at,
            is_active: key.is_active,
            created_at: key.inserted_at
          }
        end)
    })
  end

  @doc """
  Revoke an API key.

  DELETE /api/v2/account/apikey/:id
  """
  def delete(conn, %{"id" => id}) do
    case Accounts.revoke_api_key(id) do
      {:ok, _api_key} ->
        json(conn, %{message: "API key revoked successfully"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "API key not found"})
    end
  end
end

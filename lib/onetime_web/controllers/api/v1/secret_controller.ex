defmodule OneTimeWeb.API.V1.SecretController do
  use OneTimeWeb, :controller
  alias OneTime.Secrets

  action_fallback OneTimeWeb.FallbackController

  @doc """
  Creates a new secret via API.
  """
  def create(conn, %{"secret" => secret_params}) do
    ttl = Map.get(secret_params, "ttl", 604_800)
    passphrase = Map.get(secret_params, "passphrase")

    attrs = %{
      content: Map.get(secret_params, "content"),
      ttl: ttl,
      passphrase: if(passphrase == "", do: nil, else: passphrase),
      max_views: Map.get(secret_params, "max_views", 1),
      metadata: Map.get(secret_params, "metadata", %{}),
      recipient: Map.get(secret_params, "recipient")
    }

    case Secrets.create_secret(attrs) do
      {:ok, secret} ->
        secret_url = url(~p"/secret/#{secret.key}")

        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: %{
            key: secret.key,
            url: secret_url,
            expires_at: secret.expires_at,
            max_views: secret.max_views
          }
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  @doc """
  Gets secret metadata without revealing content.
  """
  def metadata(conn, %{"key" => key}) do
    case Secrets.get_secret_metadata(key) do
      {:ok, secret} ->
        json(conn, %{
          success: true,
          data: %{
            key: secret.key,
            created_at: secret.inserted_at,
            expires_at: secret.expires_at,
            max_views: secret.max_views,
            views_count: secret.views_count,
            state: secret.state,
            has_passphrase: !is_nil(secret.passphrase_hash)
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: "Secret not found"})
    end
  end

  @doc """
  Reveals a secret (marks it as viewed).
  """
  def show(conn, %{"key" => key} = params) do
    passphrase = Map.get(params, "passphrase")

    case Secrets.get_secret(key, passphrase) do
      {:ok, secret, content} ->
        json(conn, %{
          success: true,
          data: %{
            content: content,
            views_remaining: secret.max_views - secret.views_count,
            state: secret.state
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: "Secret not found"})

      {:error, :invalid_passphrase} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{success: false, error: "Invalid passphrase"})

      {:error, :not_accessible} ->
        conn
        |> put_status(:gone)
        |> json(%{success: false, error: "Secret is no longer accessible"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  @doc """
  Burns a secret immediately.
  """
  def burn(conn, %{"key" => key}) do
    case Secrets.burn_secret(key) do
      {:ok, _secret} ->
        json(conn, %{success: true, message: "Secret burned successfully"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: "Secret not found"})
    end
  end

  @doc """
  Lists user's secrets (authenticated endpoint).
  """
  def index(conn, params) do
    user = conn.assigns[:current_user]
    limit = Map.get(params, "limit", "50") |> String.to_integer()
    offset = Map.get(params, "offset", "0") |> String.to_integer()

    secrets = Secrets.list_user_secrets(user.id, limit: limit, offset: offset)

    json(conn, %{
      success: true,
      data:
        Enum.map(secrets, fn secret ->
          %{
            key: secret.key,
            created_at: secret.inserted_at,
            expires_at: secret.expires_at,
            max_views: secret.max_views,
            views_count: secret.views_count,
            state: secret.state
          }
        end)
    })
  end
end

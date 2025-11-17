defmodule OneTimeSecretWeb.API.V2.SecretController do
  use OneTimeSecretWeb, :controller

  alias OneTimeSecret.Secrets
  alias OneTimeSecret.Analytics

  action_fallback OneTimeSecretWeb.FallbackController

  @doc """
  Create a new secret.

  POST /api/v2/share
  Body: {
    "secret": "my secret content",
    "passphrase": "optional passphrase",
    "ttl": 3600,
    "recipient": "optional@email.com"
  }
  """
  def create(conn, params) do
    attrs = %{
      content: params["secret"],
      passphrase: params["passphrase"],
      ttl: parse_ttl(params["ttl"]),
      max_views: params["max_views"] || 1,
      recipient: params["recipient"],
      created_by: get_user_id(conn)
    }

    case Secrets.create_secret(attrs) do
      {:ok, %{secret: secret, metadata: metadata}} ->
        Analytics.record_event("secret_created", %{
          secret_key: secret.key,
          user_id: get_user_id(conn),
          ip_address: get_ip(conn)
        })

        conn
        |> put_status(:created)
        |> json(%{
          secret_key: secret.key,
          metadata_key: metadata.key,
          ttl: secret.ttl,
          expires_at: secret.expires_at,
          recipient: secret.recipient
        })

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Retrieve a secret by key.

  GET /api/v2/secret/:key?passphrase=optional
  """
  def show(conn, %{"key" => key} = params) do
    passphrase = params["passphrase"]

    case Secrets.get_secret(key, passphrase) do
      {:ok, secret} ->
        Analytics.record_event("secret_viewed", %{
          secret_key: key,
          user_id: get_user_id(conn),
          ip_address: get_ip(conn)
        })

        json(conn, %{
          secret: secret.content,
          metadata_key: secret.metadata_key,
          view_count: secret.view_count,
          remaining_views: secret.max_views - secret.view_count
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Secret not found or already viewed"})

      {:error, :expired} ->
        conn
        |> put_status(:gone)
        |> json(%{error: "Secret has expired"})

      {:error, :invalid_passphrase} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid passphrase"})
    end
  end

  @doc """
  Burn (delete) a secret immediately.

  POST /api/v2/secret/:key/burn
  """
  def burn(conn, %{"key" => key}) do
    case Secrets.burn_secret(key) do
      :ok ->
        Analytics.record_event("secret_burned", %{
          secret_key: key,
          user_id: get_user_id(conn),
          ip_address: get_ip(conn)
        })

        json(conn, %{message: "Secret burned successfully"})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Secret not found"})
    end
  end

  @doc """
  Get metadata for a secret without viewing the content.

  GET /api/v2/secret/:key/metadata
  """
  def metadata(conn, %{"key" => key}) do
    case Secrets.get_metadata(key) do
      {:ok, metadata} ->
        json(conn, %{
          secret_key: metadata.secret_key,
          ttl: metadata.ttl,
          view_count: metadata.view_count,
          max_views: metadata.max_views,
          expires_at: metadata.expires_at,
          passphrase_required: metadata.passphrase_required,
          recipient: metadata.recipient
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Metadata not found"})
    end
  end

  defp parse_ttl(nil), do: 3600
  defp parse_ttl(ttl) when is_binary(ttl), do: String.to_integer(ttl)
  defp parse_ttl(ttl) when is_integer(ttl), do: ttl

  defp get_user_id(conn) do
    case conn.assigns[:current_user] do
      nil -> nil
      user -> user.id
    end
  end

  defp get_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [ip | _] -> ip
      [] -> to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end
end

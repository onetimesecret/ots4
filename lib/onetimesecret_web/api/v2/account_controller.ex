defmodule OneTimeSecretWeb.API.V2.AccountController do
  use OneTimeSecretWeb, :controller

  alias OneTimeSecret.Accounts

  action_fallback OneTimeSecretWeb.FallbackController

  @doc """
  Register a new user account.

  POST /api/v2/account/register
  Body: {
    "username": "myusername",
    "email": "user@example.com",
    "password": "securepassword"
  }
  """
  def register(conn, params) do
    attrs = %{
      username: params["username"],
      email: params["email"],
      password_hash: hash_password(params["password"])
    }

    case Accounts.create_user(attrs) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> json(%{
          id: user.id,
          username: user.username,
          email: user.email,
          created_at: user.inserted_at
        })

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp hash_password(password) when is_binary(password) do
    :crypto.hash(:sha256, password) |> Base.encode64()
  end

  defp hash_password(_), do: nil
end

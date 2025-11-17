defmodule OneTimeSecretWeb.API.FallbackController do
  use OneTimeSecretWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> json(%{
      status: "error",
      message: "Secret not found or already viewed"
    })
  end

  def call(conn, {:error, :passphrase_required}) do
    conn
    |> put_status(:unauthorized)
    |> json(%{
      status: "error",
      message: "Passphrase required to decrypt this secret"
    })
  end

  def call(conn, {:error, errors}) when is_list(errors) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{
      status: "error",
      errors: format_errors(errors)
    })
  end

  def call(conn, {:error, reason}) do
    conn
    |> put_status(:internal_server_error)
    |> json(%{
      status: "error",
      message: "An error occurred: #{inspect(reason)}"
    })
  end

  defp format_errors(errors) do
    Enum.into(errors, %{}, fn {field, message} ->
      {field, message}
    end)
  end
end

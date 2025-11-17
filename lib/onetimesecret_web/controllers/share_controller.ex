defmodule OneTimeSecretWeb.ShareController do
  use OneTimeSecretWeb, :controller

  def show(conn, %{"key" => key}) do
    render(conn, :show, key: key)
  end
end

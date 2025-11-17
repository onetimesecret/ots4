defmodule OneTimeSecretWeb.PageController do
  use OneTimeSecretWeb, :controller

  def index(conn, _params) do
    render(conn, :index)
  end
end

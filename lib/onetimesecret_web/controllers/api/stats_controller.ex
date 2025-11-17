defmodule OneTimeSecretWeb.API.StatsController do
  use OneTimeSecretWeb, :controller

  alias OneTimeSecret.Secrets

  def index(conn, _params) do
    with {:ok, stats} <- Secrets.stats() do
      json(conn, %{
        status: "success",
        data: stats
      })
    end
  end
end

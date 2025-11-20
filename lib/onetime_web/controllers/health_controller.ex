defmodule OneTimeWeb.HealthController do
  use OneTimeWeb, :controller

  def check(conn, _params) do
    # Check database connectivity
    db_status =
      try do
        OneTime.Repo.query!("SELECT 1")
        "healthy"
      rescue
        _ -> "unhealthy"
      end

    status =
      if db_status == "healthy" do
        :ok
      else
        :service_unavailable
      end

    conn
    |> put_status(status)
    |> json(%{
      status: db_status,
      timestamp: DateTime.utc_now()
    })
  end
end

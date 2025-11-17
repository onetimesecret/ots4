defmodule OneTime.Repo do
  use Ecto.Repo,
    otp_app: :onetime,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the repository configuration from the environment variables.
  """
  def init(_type, config) do
    {:ok, config}
  end
end

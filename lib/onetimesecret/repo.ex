defmodule OneTimeSecret.Repo do
  @moduledoc """
  Ecto repository using Mnesia as the underlying storage.

  This provides a familiar Ecto interface while using Mnesia's
  distributed, fault-tolerant storage capabilities.
  """
  use Ecto.Repo,
    otp_app: :onetimesecret,
    adapter: Ecto.Adapters.Mnesia

  @doc """
  Dynamically loads the repository url from the
  MNESIA_DIR environment variable.
  """
  def init(_type, config) do
    {:ok, config}
  end
end

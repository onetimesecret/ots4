defmodule OneTimeSecret.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import OneTimeSecret.DataCase
    end
  end

  setup tags do
    # Clear Redis test database before each test
    unless tags[:async] do
      flush_redis()
    end

    :ok
  end

  @doc """
  Flushes the Redis test database.
  """
  def flush_redis do
    case OneTimeSecret.Redis.command(["FLUSHDB"]) do
      {:ok, _} -> :ok
      _ -> :ok
    end
  end
end

defmodule OneTimeSecret.Cache do
  @moduledoc """
  ETS-based caching layer for high-performance data access.

  This module manages ETS tables for:
  - Temporary secret storage
  - Rate limiting
  - Session management
  """
  use GenServer

  @table_name :onetimesecret_cache

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    {:ok, %{table: table}}
  end

  @doc """
  Store a value in the cache with an optional TTL (in seconds).
  """
  def put(key, value, ttl \\ nil) do
    expires_at = if ttl, do: System.system_time(:second) + ttl, else: :infinity
    :ets.insert(@table_name, {key, value, expires_at})
    :ok
  end

  @doc """
  Retrieve a value from the cache.
  """
  def get(key) do
    case :ets.lookup(@table_name, key) do
      [{^key, value, :infinity}] ->
        {:ok, value}

      [{^key, value, expires_at}] ->
        if System.system_time(:second) < expires_at do
          {:ok, value}
        else
          delete(key)
          {:error, :expired}
        end

      [] ->
        {:error, :not_found}
    end
  end

  @doc """
  Delete a value from the cache.
  """
  def delete(key) do
    :ets.delete(@table_name, key)
    :ok
  end

  @doc """
  Check if a key exists in the cache and is not expired.
  """
  def exists?(key) do
    case get(key) do
      {:ok, _} -> true
      _ -> false
    end
  end

  @doc """
  Clear all entries from the cache.
  """
  def clear do
    :ets.delete_all_objects(@table_name)
    :ok
  end
end

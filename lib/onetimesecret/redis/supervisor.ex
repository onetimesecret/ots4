defmodule OneTimeSecret.Redis.Supervisor do
  @moduledoc """
  Supervisor for Redis connection pool.
  Manages multiple Redix connections for high concurrency.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    pool_size = Application.get_env(:onetimesecret, :redis_pool_size, 10)
    redis_config = Application.get_env(:onetimesecret, :redis, [])

    children =
      for i <- 0..(pool_size - 1) do
        config =
          Keyword.merge(redis_config,
            name: :"redix_#{i}",
            sync_connect: false,
            exit_on_disconnection: false
          )

        Supervisor.child_spec({Redix, config}, id: {Redix, i})
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end

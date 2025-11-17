defmodule OneTimeSecret.Redis do
  @moduledoc """
  Redis client wrapper providing connection pooling and command execution.
  """

  @pool_size Application.compile_env(:onetimesecret, :redis_pool_size, 10)

  @doc """
  Executes a Redis command using a random connection from the pool.
  """
  @spec command(list()) :: {:ok, term()} | {:error, term()}
  def command(args) do
    Redix.command(random_pool(), args)
  end

  @doc """
  Executes a Redis command, raising on error.
  """
  @spec command!(list()) :: term() | no_return()
  def command!(args) do
    Redix.command!(random_pool(), args)
  end

  @doc """
  Executes a pipeline of Redis commands.
  """
  @spec pipeline(list(list())) :: {:ok, list()} | {:error, term()}
  def pipeline(commands) do
    Redix.pipeline(random_pool(), commands)
  end

  @doc """
  Executes a pipeline of Redis commands, raising on error.
  """
  @spec pipeline!(list(list())) :: list() | no_return()
  def pipeline!(commands) do
    Redix.pipeline!(random_pool(), commands)
  end

  @doc """
  Executes commands in a transaction (MULTI/EXEC).
  """
  @spec transaction(list(list())) :: {:ok, list()} | {:error, term()}
  def transaction(commands) do
    full_commands = [["MULTI"]] ++ commands ++ [["EXEC"]]
    pipeline(full_commands)
  end

  @doc """
  Checks if Redis is available.
  """
  @spec ping() :: :ok | {:error, term()}
  def ping do
    case command(["PING"]) do
      {:ok, "PONG"} -> :ok
      error -> error
    end
  end

  # Private functions

  defp random_pool do
    :"redix_#{:rand.uniform(@pool_size) - 1}"
  end
end

defmodule OneTimeSecret.Secrets.Storage do
  @moduledoc """
  Redis storage adapter for secrets.
  Handles atomic operations for storing and retrieving (burning) secrets.
  """

  alias OneTimeSecret.Redis
  alias OneTimeSecret.Secrets.Secret

  @secret_prefix "secret:"
  @metadata_suffix ":metadata"
  @views_suffix ":views"

  @doc """
  Stores a secret in Redis with TTL.
  """
  @spec store(Secret.t()) :: {:ok, Secret.t()} | {:error, term()}
  def store(%Secret{} = secret) do
    redis_key = build_key(secret.key)
    hash_data = Secret.to_redis_hash(secret)

    commands = [
      ["HSET", redis_key | hash_data],
      ["EXPIRE", redis_key, secret.ttl],
      ["SET", redis_key <> @metadata_suffix, build_metadata(secret), "EX", secret.ttl]
    ]

    case Redis.pipeline(commands) do
      {:ok, _} -> {:ok, %{secret | value: nil}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Retrieves and deletes a secret atomically (burn after reading).
  """
  @spec fetch_and_burn(String.t()) :: {:ok, Secret.t()} | {:error, :not_found | term()}
  def fetch_and_burn(key) do
    redis_key = build_key(key)

    # Use Lua script for atomic get-and-delete
    script = """
    local data = redis.call('HGETALL', KEYS[1])
    if next(data) == nil then
      return nil
    end
    redis.call('DEL', KEYS[1])
    redis.call('DEL', KEYS[2])
    redis.call('DEL', KEYS[3])
    return data
    """

    keys = [
      redis_key,
      redis_key <> @metadata_suffix,
      redis_key <> @views_suffix
    ]

    case Redis.command(["EVAL", script, 3] ++ keys) do
      {:ok, nil} ->
        {:error, :not_found}

      {:ok, data} ->
        secret = Secret.from_redis_hash(data)
        {:ok, secret}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Checks if a secret exists without burning it.
  """
  @spec exists?(String.t()) :: boolean()
  def exists?(key) do
    redis_key = build_key(key)

    case Redis.command(["EXISTS", redis_key]) do
      {:ok, 1} -> true
      _ -> false
    end
  end

  @doc """
  Gets metadata about a secret without burning it.
  """
  @spec get_metadata(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_metadata(key) do
    redis_key = build_key(key) <> @metadata_suffix

    case Redis.command(["GET", redis_key]) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, data} -> {:ok, Jason.decode!(data)}
      {:error, _} -> {:error, :not_found}
    end
  end

  @doc """
  Records a view attempt (for analytics).
  """
  @spec record_view(String.t(), map()) :: :ok
  def record_view(key, view_data \\ %{}) do
    redis_key = build_key(key) <> @views_suffix
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    data =
      Map.merge(view_data, %{timestamp: timestamp})
      |> Jason.encode!()

    Redis.command(["RPUSH", redis_key, data])
    :ok
  end

  @doc """
  Deletes a secret (for cleanup/management).
  """
  @spec delete(String.t()) :: :ok | {:error, term()}
  def delete(key) do
    redis_key = build_key(key)

    commands = [
      ["DEL", redis_key],
      ["DEL", redis_key <> @metadata_suffix],
      ["DEL", redis_key <> @views_suffix]
    ]

    case Redis.pipeline(commands) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Counts total secrets in storage.
  """
  @spec count() :: {:ok, integer()} | {:error, term()}
  def count do
    case Redis.command(["KEYS", @secret_prefix <> "*"]) do
      {:ok, keys} ->
        # Filter out metadata and views keys
        count =
          keys
          |> Enum.reject(&String.contains?(&1, @metadata_suffix))
          |> Enum.reject(&String.contains?(&1, @views_suffix))
          |> length()

        {:ok, count}

      error ->
        error
    end
  end

  # Private functions

  defp build_key(key) do
    @secret_prefix <> key
  end

  defp build_metadata(secret) do
    %{
      key: secret.key,
      created_at: DateTime.to_iso8601(secret.created_at),
      expires_at: DateTime.to_iso8601(secret.expires_at),
      passphrase_required: secret.passphrase_required,
      recipient: secret.recipient
    }
    |> Jason.encode!()
  end
end

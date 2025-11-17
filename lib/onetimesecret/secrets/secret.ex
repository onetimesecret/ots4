defmodule OneTimeSecret.Secrets.Secret do
  @moduledoc """
  Core secret data structure representing a one-time secret.
  """

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t() | nil,
          passphrase_required: boolean(),
          ttl: integer(),
          created_at: DateTime.t(),
          expires_at: DateTime.t(),
          recipient: String.t() | nil,
          metadata: map()
        }

  @enforce_keys [:key, :ttl]
  defstruct [
    :key,
    :value,
    :passphrase_required,
    :ttl,
    :created_at,
    :expires_at,
    :recipient,
    metadata: %{}
  ]

  @doc """
  Creates a new secret struct with generated key and timestamps.
  """
  @spec new(map()) :: t()
  def new(attrs \\ %{}) do
    now = DateTime.utc_now()
    ttl = Map.get(attrs, :ttl, default_ttl())
    key = generate_key()

    %__MODULE__{
      key: key,
      value: Map.get(attrs, :value),
      passphrase_required: Map.get(attrs, :passphrase_required, false),
      ttl: ttl,
      created_at: now,
      expires_at: DateTime.add(now, ttl, :second),
      recipient: Map.get(attrs, :recipient),
      metadata: Map.get(attrs, :metadata, %{})
    }
  end

  @doc """
  Validates secret attributes.
  """
  @spec validate(map()) :: {:ok, map()} | {:error, keyword()}
  def validate(attrs) do
    errors = []

    errors =
      if is_nil(attrs[:value]) or attrs[:value] == "" do
        [{:value, "cannot be blank"} | errors]
      else
        errors
      end

    errors =
      if byte_size(attrs[:value] || "") > max_size() do
        [{:value, "exceeds maximum size of #{max_size()} bytes"} | errors]
      else
        errors
      end

    errors =
      if attrs[:ttl] && attrs[:ttl] > max_ttl() do
        [{:ttl, "exceeds maximum TTL of #{max_ttl()} seconds"} | errors]
      else
        errors
      end

    errors =
      if attrs[:ttl] && attrs[:ttl] < 0 do
        [{:ttl, "must be positive"} | errors]
      else
        errors
      end

    if Enum.empty?(errors) do
      {:ok, attrs}
    else
      {:error, errors}
    end
  end

  @doc """
  Converts secret to Redis hash format (list of key-value pairs).
  """
  @spec to_redis_hash(t()) :: list()
  def to_redis_hash(%__MODULE__{} = secret) do
    [
      "key",
      secret.key,
      "value",
      secret.value || "",
      "passphrase_required",
      to_string(secret.passphrase_required),
      "ttl",
      to_string(secret.ttl),
      "created_at",
      DateTime.to_iso8601(secret.created_at),
      "expires_at",
      DateTime.to_iso8601(secret.expires_at),
      "recipient",
      secret.recipient || "",
      "metadata",
      Jason.encode!(secret.metadata)
    ]
  end

  @doc """
  Converts Redis hash (list of key-value pairs) to secret struct.
  """
  @spec from_redis_hash(list()) :: t() | nil
  def from_redis_hash([]), do: nil

  def from_redis_hash(hash) when is_list(hash) do
    map = hash |> Enum.chunk_every(2) |> Map.new(fn [k, v] -> {k, v} end)

    %__MODULE__{
      key: map["key"],
      value: map["value"],
      passphrase_required: map["passphrase_required"] == "true",
      ttl: String.to_integer(map["ttl"] || "0"),
      created_at: parse_datetime(map["created_at"]),
      expires_at: parse_datetime(map["expires_at"]),
      recipient: if(map["recipient"] == "", do: nil, else: map["recipient"]),
      metadata: Jason.decode!(map["metadata"] || "{}")
    }
  end

  # Private functions

  defp generate_key do
    Nanoid.generate(21)
  end

  defp default_ttl do
    Application.get_env(:onetimesecret, :default_ttl, 86400)
  end

  defp max_ttl do
    Application.get_env(:onetimesecret, :max_ttl, 604_800)
  end

  defp max_size do
    Application.get_env(:onetimesecret, :max_secret_size, 1_000_000)
  end

  defp parse_datetime(nil), do: DateTime.utc_now()

  defp parse_datetime(str) do
    case DateTime.from_iso8601(str) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now()
    end
  end
end

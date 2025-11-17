defmodule OneTime.Guardian do
  @moduledoc """
  Guardian implementation for JWT-based authentication.
  """
  use Guardian, otp_app: :onetime

  alias OneTime.Accounts

  def subject_for_token(%{id: id}, _claims) do
    {:ok, to_string(id)}
  end

  def subject_for_token(_, _) do
    {:error, :invalid_resource}
  end

  def resource_from_claims(%{"sub" => id}) do
    case Accounts.get_user(id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :invalid_claims}
  end
end

defmodule OneTime.Guardian.Serializer do
  @moduledoc """
  Serializer for Guardian tokens.
  """

  def for_token(%{id: id}), do: {:ok, "User:#{id}"}
  def for_token(_), do: {:error, "Unknown resource type"}

  def from_token("User:" <> id), do: {:ok, %{id: id}}
  def from_token(_), do: {:error, "Unknown resource type"}
end

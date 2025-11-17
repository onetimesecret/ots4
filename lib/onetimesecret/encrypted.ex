defmodule OneTimeSecret.Encrypted.Binary do
  @moduledoc """
  Custom Ecto type for encrypted binary data.
  """
  use Cloak.Ecto.Binary, vault: OneTimeSecret.Vault
end

defmodule OneTimeSecret.Encrypted.Map do
  @moduledoc """
  Custom Ecto type for encrypted map data.
  """
  use Cloak.Ecto.Map, vault: OneTimeSecret.Vault
end

defmodule OneTimeSecret.Vault do
  @moduledoc """
  Encryption vault using Cloak for encrypting sensitive data.

  This module provides AES-GCM encryption for secrets and other sensitive data.
  The encryption key is configured via runtime configuration.
  """
  use Cloak.Vault, otp_app: :onetimesecret

  @impl GenServer
  def init(config) do
    # Mark this process as sensitive to prevent inspection
    :erlang.process_flag(:sensitive, true)

    config =
      Keyword.put(config, :ciphers, [
        default: resolve_cipher(config[:ciphers][:default])
      ])

    {:ok, config}
  end

  defp resolve_cipher({cipher_module, opts}) do
    {cipher_module, opts}
  end
end

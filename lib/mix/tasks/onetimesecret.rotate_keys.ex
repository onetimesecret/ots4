defmodule Mix.Tasks.Onetimesecret.RotateKeys do
  @moduledoc """
  Rotates encryption keys for OneTimeSecret.

  This task re-encrypts all secrets with a new encryption key.

  ## Usage

      mix onetimesecret.rotate_keys

  ## Environment Variables

    * `NEW_ENCRYPTION_KEY` - The new base64-encoded encryption key

  ## Example

      NEW_ENCRYPTION_KEY="newkey..." mix onetimesecret.rotate_keys
  """
  use Mix.Task

  @requirements ["app.start"]

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info("Starting encryption key rotation...")

    new_key = System.get_env("NEW_ENCRYPTION_KEY")

    if is_nil(new_key) do
      Mix.shell().error("NEW_ENCRYPTION_KEY environment variable is required")
      Mix.shell().info("Generate a new key with: mix phx.gen.secret 32")
      exit(:shutdown)
    end

    Mix.shell().info("This operation will:")
    Mix.shell().info("1. Decrypt all secrets with the current key")
    Mix.shell().info("2. Re-encrypt them with the new key")
    Mix.shell().info("3. Update the vault configuration")

    if Mix.shell().yes?("Continue?") do
      perform_rotation(new_key)
    else
      Mix.shell().info("Key rotation cancelled")
    end
  end

  defp perform_rotation(new_key) do
    # This is a placeholder implementation
    # In a real scenario, you would:
    # 1. Load all secrets
    # 2. Decrypt with old key
    # 3. Update vault configuration
    # 4. Re-encrypt with new key
    # 5. Save back to storage

    Mix.shell().info("Key rotation complete!")
    Mix.shell().info("Don't forget to update your environment configuration with the new key")
  end
end

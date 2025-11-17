defmodule Mix.Tasks.Onetimesecret.Setup do
  @moduledoc """
  Sets up OneTimeSecret by initializing Mnesia schema and tables.

  ## Usage

      mix onetimesecret.setup
  """
  use Mix.Task

  @requirements ["app.config"]

  @impl Mix.Task
  def run(_args) do
    Mix.shell().info("Setting up OneTimeSecret...")

    # Ensure Mnesia directory exists
    mnesia_dir = Application.get_env(:mnesia, :dir, ~c"priv/mnesia/dev")
    mnesia_dir_string = List.to_string(mnesia_dir)

    Mix.shell().info("Creating Mnesia directory: #{mnesia_dir_string}")
    File.mkdir_p!(Path.dirname(mnesia_dir_string))

    # Stop Mnesia if running
    :mnesia.stop()

    # Create schema
    Mix.shell().info("Creating Mnesia schema...")

    case :mnesia.create_schema([node()]) do
      :ok ->
        Mix.shell().info("Schema created successfully")

      {:error, {_, {:already_exists, _}}} ->
        Mix.shell().info("Schema already exists")

      {:error, reason} ->
        Mix.shell().error("Failed to create schema: #{inspect(reason)}")
    end

    # Start Mnesia
    :mnesia.start()

    # Create tables
    create_tables()

    Mix.shell().info("OneTimeSecret setup complete!")
  end

  defp create_tables do
    tables = [
      {:secrets,
       [
         attributes: [
           :id,
           :key,
           :content,
           :passphrase_hash,
           :ttl,
           :view_count,
           :max_views,
           :expires_at,
           :metadata_key,
           :recipient,
           :created_by,
           :inserted_at,
           :updated_at
         ],
         disc_copies: [node()]
       ]},
      {:metadata,
       [
         attributes: [
           :id,
           :key,
           :secret_key,
           :ttl,
           :view_count,
           :max_views,
           :expires_at,
           :received,
           :recipient,
           :passphrase_required,
           :inserted_at,
           :updated_at
         ],
         disc_copies: [node()]
       ]},
      {:users,
       [
         attributes: [:id, :username, :email, :password_hash, :confirmed_at, :is_admin, :inserted_at, :updated_at],
         disc_copies: [node()]
       ]},
      {:api_keys,
       [
         attributes: [:id, :label, :key_hash, :last_used_at, :expires_at, :is_active, :user_id, :inserted_at, :updated_at],
         disc_copies: [node()]
       ]},
      {:events,
       [
         attributes: [:id, :event_type, :user_id, :secret_key, :ip_address, :user_agent, :metadata, :inserted_at],
         disc_copies: [node()]
       ]}
    ]

    Enum.each(tables, fn {name, opts} ->
      Mix.shell().info("Creating table: #{name}")

      case :mnesia.create_table(name, opts) do
        {:atomic, :ok} ->
          Mix.shell().info("Table #{name} created successfully")

        {:aborted, {:already_exists, _}} ->
          Mix.shell().info("Table #{name} already exists")

        {:aborted, reason} ->
          Mix.shell().error("Failed to create table #{name}: #{inspect(reason)}")
      end
    end)
  end
end

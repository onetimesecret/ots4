defmodule OneTime.Repo.Migrations.CreateSecrets do
  use Ecto.Migration

  def change do
    create table(:secrets, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key, :string, null: false
      add :encrypted_content, :binary, null: false
      add :nonce, :binary, null: false
      add :auth_tag, :binary, null: false
      add :passphrase_hash, :string
      add :burn_after_reading, :boolean, default: true, null: false
      add :max_views, :integer, default: 1, null: false
      add :views_count, :integer, default: 0, null: false
      add :expires_at, :utc_datetime, null: false
      add :metadata, :map, default: %{}
      add :recipient, :string
      add :state, :string, default: "active", null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:secrets, [:key])
    create index(:secrets, [:user_id])
    create index(:secrets, [:expires_at])
    create index(:secrets, [:state])
    create index(:secrets, [:inserted_at])
  end
end

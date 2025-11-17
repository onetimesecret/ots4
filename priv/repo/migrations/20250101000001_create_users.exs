defmodule OneTime.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :username, :string
      add :password_hash, :string, null: false
      add :api_key, :string
      add :is_active, :boolean, default: true, null: false
      add :is_admin, :boolean, default: false, null: false
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:username])
    create unique_index(:users, [:api_key])
    create index(:users, [:is_active])
  end
end

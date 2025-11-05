defmodule FinTrack.Repo.Migrations.CreateInvestments do
  use Ecto.Migration

  def change do
    create table(:investments) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :initial_value, :decimal, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:investments, [:user_id])
  end
end

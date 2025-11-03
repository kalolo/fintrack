defmodule Invoices.Repo.Migrations.CreateInvestmentValueCaptures do
  use Ecto.Migration

  def change do
    create table(:investment_value_captures) do
      add :investment_id, references(:investments, on_delete: :delete_all), null: false
      add :captured_at, :date, null: false
      add :value, :decimal, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:investment_value_captures, [:investment_id])
    create unique_index(:investment_value_captures, [:investment_id, :captured_at])
  end
end

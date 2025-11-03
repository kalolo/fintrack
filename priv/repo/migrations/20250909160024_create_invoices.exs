defmodule Invoices.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:invoices) do
      add :invoice_number, :string, null: false
      add :description, :string, null: false
      add :amount, :decimal, precision: 15, scale: 2, null: false
      add :date, :date, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:invoices, [:user_id])
    create unique_index(:invoices, [:invoice_number])
  end
end

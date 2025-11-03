defmodule Invoices.Repo.Migrations.AddPaymentMethodToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add :payment_method, :string, default: "debit", null: false
    end
  end
end

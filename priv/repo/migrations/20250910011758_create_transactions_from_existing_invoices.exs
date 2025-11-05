defmodule FinTrack.Repo.Migrations.CreateTransactionsFromExistingInvoices do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # Get all existing invoices
    invoices =
      from(i in "invoices",
        select: [
          :id,
          :invoice_number,
          :description,
          :amount,
          :date,
          :user_id,
          :inserted_at,
          :updated_at
        ]
      )
      |> FinTrack.Repo.all()

    IO.puts("Found #{length(invoices)} invoices to create transactions for...")

    # Insert corresponding income transactions for each invoice
    Enum.each(invoices, fn invoice ->
      # Use the invoice date, or fall back to invoice inserted_at if date is nil
      transaction_timestamp =
        invoice.date
        |> case do
          nil -> NaiveDateTime.new!(invoice.inserted_at |> NaiveDateTime.to_date(), ~T[12:00:00])
          date -> NaiveDateTime.new!(date, ~T[12:00:00])
        end

      transaction_attrs = %{
        type: "income",
        amount: invoice.amount,
        description: "Invoice #{invoice.invoice_number} - #{invoice.description}",
        timestamp: transaction_timestamp,
        user_id: invoice.user_id,
        inserted_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      }

      FinTrack.Repo.insert_all("transactions", [transaction_attrs])
    end)

    IO.puts(
      "Successfully created #{length(invoices)} income transactions from existing invoices."
    )
  end

  def down do
    # Remove all transactions that were created from invoices
    # We can identify them by their description pattern
    from(t in "transactions",
      where: like(t.description, "Invoice % - %") and t.type == "income"
    )
    |> FinTrack.Repo.delete_all()
  end
end

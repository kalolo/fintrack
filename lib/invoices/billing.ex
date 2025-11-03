defmodule Invoices.Billing do
  @moduledoc """
  The Billing context.
  """

  import Ecto.Query, warn: false
  alias Invoices.Repo
  alias Invoices.Billing.Invoice
  alias Invoices.Billing.Transaction

  def list_invoices_for_user(user_id, params \\ %{}) do
    sort_by = params["sort_by"] || "invoice_number"
    sort_order = params["sort_order"] || "desc"

    order_by_clause = build_order_by_clause(sort_by, sort_order)

    from(i in Invoice,
      where: i.user_id == ^user_id,
      order_by: ^order_by_clause
    )
    |> Repo.paginate(params)
  end

  defp build_order_by_clause(sort_by, sort_order) do
    direction = if sort_order == "desc", do: :desc, else: :asc

    case sort_by do
      "date" -> [{direction, :date}]
      "amount" -> [{direction, :amount}]
      "invoice_number" -> [{direction, :invoice_number}]
      _ -> [asc: :invoice_number]
    end
  end

  def get_invoice!(id), do: Repo.get!(Invoice, id)

  def create_invoice(attrs, user_id) do
    invoice_number = Invoice.generate_invoice_number()

    # Ensure string keys for consistency with form params and proper types
    attrs =
      attrs
      |> Map.put("invoice_number", invoice_number)
      |> Map.put("user_id", to_string(user_id))

    %Invoice{}
    |> Invoice.changeset(attrs)
    |> Repo.insert()
  end

  def update_invoice(%Invoice{} = invoice, attrs) do
    invoice
    |> Invoice.changeset(attrs)
    |> Repo.update()
  end

  def change_invoice(%Invoice{} = invoice, attrs \\ %{}) do
    Invoice.changeset(invoice, attrs)
  end

  def delete_invoice(%Invoice{} = invoice) do
    Repo.delete(invoice)
  end

  # Static configuration from config
  def get_client_info do
    Application.get_env(:invoices, :invoice_config)[:client]
  end

  def get_bill_to_info do
    Application.get_env(:invoices, :invoice_config)[:bill_to]
  end

  # Transaction functions

  def list_transactions_for_user(user_id, params \\ %{}) do
    sort_by = params["sort_by"] || "timestamp"
    sort_order = params["sort_order"] || "desc"

    order_by_clause = build_transaction_order_by_clause(sort_by, sort_order)

    from(t in Transaction,
      where: t.user_id == ^user_id,
      order_by: ^order_by_clause
    )
    |> Repo.paginate(params)
  end

  defp build_transaction_order_by_clause(sort_by, sort_order) do
    direction = if sort_order == "desc", do: :desc, else: :asc

    case sort_by do
      "timestamp" -> [{direction, :timestamp}]
      "amount" -> [{direction, :amount}]
      "type" -> [{direction, :type}]
      "description" -> [{direction, :description}]
      _ -> [desc: :timestamp]
    end
  end

  def get_transaction!(id), do: Repo.get!(Transaction, id)

  def create_transaction(attrs, user_id) do
    attrs =
      attrs
      |> Map.put("user_id", user_id)

    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
  end

  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end

  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end

  def create_income_transaction_from_invoice(invoice, user_id) do
    attrs = %{
      "type" => "income",
      "amount" => invoice.amount,
      "description" => "Invoice #{invoice.invoice_number} - #{invoice.description}",
      "timestamp" => invoice.date || NaiveDateTime.local_now()
    }

    create_transaction(attrs, user_id)
  end

  # Dashboard functions

  def get_dashboard_data(user_id, date_from, date_to) do
    transactions = get_transactions_in_date_range(user_id, date_from, date_to)

    %{
      metrics: calculate_metrics(transactions),
      monthly_data: group_by_month(transactions),
      daily_data: group_by_day(transactions),
      income_expense_ratio: calculate_income_expense_ratio(transactions),
      cumulative_flow: calculate_cumulative_flow(transactions),
      payment_method_breakdown: calculate_payment_method_breakdown(transactions)
    }
  end

  def get_all_time_monthly_summary(user_id) do
    from(t in Transaction,
      where: t.user_id == ^user_id,
      order_by: [asc: t.timestamp]
    )
    |> Repo.all()
    |> group_by_month()
    |> Enum.map(fn month_data ->
      margin = if month_data.income > 0 do
        (month_data.income - month_data.expenses) / month_data.income * 100
      else
        0
      end

      Map.put(month_data, :margin, margin)
    end)
  end

  defp get_transactions_in_date_range(user_id, date_from, date_to) do
    from(t in Transaction,
      where: t.user_id == ^user_id,
      where: t.timestamp >= ^date_from and t.timestamp <= ^date_to,
      order_by: [asc: t.timestamp]
    )
    |> Repo.all()
  end

  defp calculate_metrics(transactions) do
    income =
      transactions
      |> Enum.filter(&(&1.type == "income"))
      |> Enum.map(&Decimal.to_float(&1.amount))
      |> Enum.sum()

    expenses =
      transactions
      |> Enum.filter(&(&1.type == "expense"))
      |> Enum.map(&Decimal.to_float(&1.amount))
      |> Enum.sum()

    %{
      total_income: income,
      total_expenses: expenses,
      net_profit: income - expenses,
      profit_margin: if(income > 0, do: (income - expenses) / income * 100, else: 0),
      transaction_count: length(transactions)
    }
  end

  defp group_by_month(transactions) do
    transactions
    |> Enum.group_by(fn t ->
      t.timestamp |> NaiveDateTime.to_date() |> Date.beginning_of_month()
    end)
    |> Enum.map(fn {month, month_transactions} ->
      income =
        month_transactions
        |> Enum.filter(&(&1.type == "income"))
        |> Enum.map(&Decimal.to_float(&1.amount))
        |> Enum.sum()

      expenses =
        month_transactions
        |> Enum.filter(&(&1.type == "expense"))
        |> Enum.map(&Decimal.to_float(&1.amount))
        |> Enum.sum()

      %{
        month: month,
        income: income,
        expenses: expenses,
        net: income - expenses
      }
    end)
    |> Enum.sort_by(& &1.month, Date)
  end

  defp group_by_day(transactions) do
    transactions
    |> Enum.group_by(fn t ->
      t.timestamp |> NaiveDateTime.to_date()
    end)
    |> Enum.map(fn {date, day_transactions} ->
      income =
        day_transactions
        |> Enum.filter(&(&1.type == "income"))
        |> Enum.map(&Decimal.to_float(&1.amount))
        |> Enum.sum()

      expenses =
        day_transactions
        |> Enum.filter(&(&1.type == "expense"))
        |> Enum.map(&Decimal.to_float(&1.amount))
        |> Enum.sum()

      %{
        date: date,
        income: income,
        expenses: expenses,
        net: income - expenses
      }
    end)
    |> Enum.sort_by(& &1.date, Date)
  end

  defp calculate_income_expense_ratio(transactions) do
    income =
      transactions
      |> Enum.filter(&(&1.type == "income"))
      |> Enum.map(&Decimal.to_float(&1.amount))
      |> Enum.sum()

    expenses =
      transactions
      |> Enum.filter(&(&1.type == "expense"))
      |> Enum.map(&Decimal.to_float(&1.amount))
      |> Enum.sum()

    total = income + expenses

    if total > 0 do
      %{
        income_percentage: income / total * 100,
        expense_percentage: expenses / total * 100,
        income_amount: income,
        expense_amount: expenses
      }
    else
      %{
        income_percentage: 0,
        expense_percentage: 0,
        income_amount: 0,
        expense_amount: 0
      }
    end
  end

  defp calculate_cumulative_flow(transactions) do
    transactions
    |> Enum.sort_by(& &1.timestamp, NaiveDateTime)
    |> Enum.reduce({[], 0}, fn transaction, {acc, running_total} ->
      amount = Decimal.to_float(transaction.amount)

      new_total =
        case transaction.type do
          "income" -> running_total + amount
          "expense" -> running_total - amount
        end

      entry = %{
        date: NaiveDateTime.to_date(transaction.timestamp),
        amount: new_total,
        transaction_type: transaction.type
      }

      {[entry | acc], new_total}
    end)
    |> elem(0)
    |> Enum.reverse()
  end

  defp calculate_payment_method_breakdown(transactions) do
    transactions
    |> Enum.group_by(& &1.payment_method)
    |> Enum.map(fn {payment_method, method_transactions} ->
      income_amount =
        method_transactions
        |> Enum.filter(&(&1.type == "income"))
        |> Enum.map(&Decimal.to_float(&1.amount))
        |> Enum.sum()

      expense_amount =
        method_transactions
        |> Enum.filter(&(&1.type == "expense"))
        |> Enum.map(&Decimal.to_float(&1.amount))
        |> Enum.sum()

      net_amount = income_amount - expense_amount

      %{
        payment_method: payment_method,
        total_amount: net_amount,
        income_amount: income_amount,
        expense_amount: expense_amount,
        transaction_count: length(method_transactions),
        display_name: Invoices.Billing.Transaction.payment_method_display(payment_method)
      }
    end)
    |> Enum.sort_by(& &1.total_amount, :desc)
  end
end

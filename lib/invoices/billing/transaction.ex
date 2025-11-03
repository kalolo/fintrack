defmodule Invoices.Billing.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field :type, :string
    field :amount, :decimal
    field :description, :string
    field :timestamp, :naive_datetime
    field :payment_method, :string, default: "debit"
    belongs_to :user, Invoices.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @payment_methods ~w(debit credit amex cash bank_transfer)

  def payment_methods, do: @payment_methods

  def payment_method_options do
    [
      {"Debit Card", "debit"},
      {"Credit Card", "credit"},
      {"American Express", "amex"},
      {"Cash", "cash"},
      {"Bank Transfer", "bank_transfer"}
    ]
  end

  def payment_method_display(method) do
    case method do
      "debit" -> "Debit Card"
      "credit" -> "Credit Card"
      "amex" -> "American Express"
      "cash" -> "Cash"
      "bank_transfer" -> "Bank Transfer"
      _ -> method
    end
  end

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:type, :amount, :description, :timestamp, :payment_method, :user_id])
    |> normalize_amount()
    |> validate_required([:type, :amount, :description, :user_id])
    |> validate_inclusion(:type, ["income", "expense"])
    |> validate_inclusion(:payment_method, @payment_methods)
    |> validate_number(:amount, greater_than: 0)
    |> put_default_timestamp()
    |> put_default_payment_method()
  end

  defp normalize_amount(changeset) do
    case get_change(changeset, :amount) do
      nil ->
        changeset

      amount_value when is_binary(amount_value) ->
        try do
          # Handle integer strings by converting them to decimal format
          decimal_amount = Decimal.new(amount_value)
          put_change(changeset, :amount, decimal_amount)
        rescue
          _ -> changeset
        end

      _ ->
        changeset
    end
  end

  defp put_default_timestamp(changeset) do
    case get_change(changeset, :timestamp) do
      nil ->
        # Only set timestamp to now for new records (no id)
        if changeset.data.id do
          # Existing record - keep existing timestamp
          changeset
        else
          # New record - set to now
          put_change(changeset, :timestamp, NaiveDateTime.local_now())
        end

      _ ->
        changeset
    end
  end

  defp put_default_payment_method(changeset) do
    case get_change(changeset, :payment_method) do
      nil ->
        # Only set payment method to debit for new records (no id)
        if changeset.data.id do
          # Existing record - keep existing payment method
          changeset
        else
          # New record - default to debit
          put_change(changeset, :payment_method, "debit")
        end

      _ ->
        changeset
    end
  end
end

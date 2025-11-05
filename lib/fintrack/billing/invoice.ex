defmodule FinTrack.Billing.Invoice do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "invoices" do
    field :invoice_number, :string
    field :description, :string
    field :amount, :decimal
    field :date, :date
    belongs_to :user, FinTrack.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(invoice, attrs) do
    invoice
    |> cast(attrs, [:description, :amount, :date, :invoice_number, :user_id])
    |> validate_required([:description, :amount, :invoice_number, :user_id])
    |> put_date_if_missing()
    |> validate_number(:amount, greater_than: 0)
  end

  defp put_date_if_missing(changeset) do
    if get_field(changeset, :date) do
      changeset
    else
      put_change(changeset, :date, Date.utc_today())
    end
  end

  def generate_invoice_number do
    # Get the highest existing invoice number
    highest =
      from(i in __MODULE__,
        select: i.invoice_number,
        order_by: [desc: i.invoice_number],
        limit: 1
      )
      |> FinTrack.Repo.one()

    case highest do
      # Start at 100106 as requested
      nil ->
        "100106"

      number ->
        {int_number, _} = Integer.parse(number)
        Integer.to_string(int_number + 1)
    end
  end
end

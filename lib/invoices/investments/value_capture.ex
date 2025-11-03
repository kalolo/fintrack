defmodule Invoices.Investments.ValueCapture do
  use Ecto.Schema
  import Ecto.Changeset

  schema "investment_value_captures" do
    field :captured_at, :date
    field :value, :decimal
    belongs_to :investment, Invoices.Investments.Investment

    timestamps(type: :utc_datetime)
  end

  def changeset(value_capture, attrs) do
    value_capture
    |> cast(attrs, [:captured_at, :value, :investment_id])
    |> validate_required([:captured_at, :value, :investment_id])
    |> assoc_constraint(:investment)
  end
end

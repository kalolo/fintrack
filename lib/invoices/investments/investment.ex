defmodule Invoices.Investments.Investment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "investments" do
    field :name, :string
    field :initial_value, :decimal
    belongs_to :user, Invoices.Accounts.User
    has_many :value_captures, Invoices.Investments.ValueCapture

    timestamps(type: :utc_datetime)
  end

  def changeset(investment, attrs) do
    investment
    |> cast(attrs, [:name, :initial_value, :user_id])
    |> validate_required([:name, :initial_value, :user_id])
    |> assoc_constraint(:user)
    |> cast_assoc(:value_captures)
  end

  # def latest_value(investment) do
  #   value =
  #     case investment.value_captures |> Enum.sort_by(& &1.captured_at, {:desc, Date}) do
  #       [latest | _] -> latest.value
  #       [] -> investment.initial_value
  #     end

  #   Decimal.to_float(value)
  # end

  def previous_value(investment) do
    sorted_captures = investment.value_captures |> Enum.sort_by(& &1.captured_at, {:desc, Date})

    value =
      case sorted_captures do
        [_latest, previous | _] -> previous.value
        [_latest] -> investment.initial_value
        [] -> investment.initial_value
      end

    Decimal.to_float(value)
  end

  def latest_value(investment) do
    investment.value_captures
    |> Enum.max_by(& &1.captured_at, Date)
    |> Map.fetch!(:value)
    |> Decimal.to_float()
  end

  # def previous_value(investment) do
  #   {latest, previous} =
  #     investment.value_captures
  #     |> Enum.reduce({nil, nil}, fn capture, {latest, previous} ->
  #       cond do
  #         is_nil(latest) or Date.compare(capture.captured_at, latest.captured_at) == :gt ->
  #           {capture, latest}

  #         is_nil(previous) or Date.compare(capture.captured_at, previous.captured_at) == :gt ->
  #           {latest, capture}

  #         true ->
  #           {latest, previous}
  #       end
  #     end)

  #   value =
  #     cond do
  #       previous -> previous.value
  #       latest -> investment.initial_value
  #       true -> investment.initial_value
  #     end

  #   Decimal.to_float(value)
  # end
end

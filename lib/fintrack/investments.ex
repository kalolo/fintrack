defmodule FinTrack.Investments do
  import Ecto.Query, warn: false
  alias FinTrack.Repo
  alias FinTrack.Investments.{Investment, ValueCapture}

  def list_investments() do
    Investment
    |> Repo.all()
  end

  def list_investments_for_user(user_id) do
    Investment
    |> where(user_id: ^user_id)
    |> preload(value_captures: ^from(vc in ValueCapture, order_by: vc.captured_at))
    |> Repo.all()
  end

  def get_investment!(id, user_id) do
    Investment
    |> where([i], i.id == ^id and i.user_id == ^user_id)
    |> preload(:value_captures)
    |> Repo.one!()
  end

  def create_investment(attrs, user_id) do
    %Investment{}
    |> Investment.changeset(Map.put(attrs, "user_id", user_id))
    |> Repo.insert()
  end

  def add_value_capture(investment_id, attrs) do
    %ValueCapture{}
    |> ValueCapture.changeset(Map.put(attrs, "investment_id", investment_id))
    |> Repo.insert()
  end

  def delete_investment(%Investment{} = investment), do: Repo.delete(investment)

  def list_value_captures(investment_id) do
    ValueCapture
    |> where([vc], vc.investment_id == ^investment_id)
    |> order_by(asc: :captured_at)
    |> Repo.all()
  end

  def get_value_capture!(id) do
    Repo.get!(ValueCapture, id)
  end

  def update_value_capture(%ValueCapture{} = value_capture, attrs) do
    value_capture
    |> ValueCapture.changeset(attrs)
    |> Repo.update()
  end

  def total_in_investments(user_id) do
    latest_value_captures =
      from vc in ValueCapture,
        join: i in Investment,
        on: vc.investment_id == i.id,
        where: i.user_id == ^user_id,
        group_by: vc.investment_id,
        select: %{
          investment_id: vc.investment_id,
          latest_value: max(vc.value),
          latest_date: max(vc.captured_at)
        }

    query =
      from i in Investment,
        left_join: lvc in subquery(latest_value_captures),
        on: i.id == lvc.investment_id,
        where: i.user_id == ^user_id,
        select: fragment("COALESCE(?, ?)", lvc.latest_value, i.initial_value)

    values = Repo.all(query)
    values |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end
end

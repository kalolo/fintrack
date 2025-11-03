defmodule Invoices.BillingFixtures do
  @moduledoc """
  This module defines test fixtures for Billing context.
  You can use it in your tests as:
      use Invoices.DataCase

      import Invoices.BillingFixtures
  """

  alias Invoices.Billing
  import Invoices.AccountsFixtures

  @doc """
  Generate a transaction.
  If no user_id is provided, creates a new user.
  """
  def transaction_fixture(attrs \\ %{}) do
    user_id =
      case Map.get(attrs, "user_id") || Map.get(attrs, :user_id) do
        nil ->
          user = user_fixture()
          user.id

        id ->
          id
      end

    params =
      attrs
      |> Enum.into(%{
        "amount" => 120.5,
        "description" => "some description",
        "timestamp" => ~N[2025-09-08 21:25:00],
        "type" => "income"
      })
      |> Map.delete("user_id")
      |> Map.delete(:user_id)

    {:ok, transaction} = Billing.create_transaction(params, user_id)
    transaction
  end
end

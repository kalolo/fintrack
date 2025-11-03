defmodule Invoices.BillingFixtures do
  @moduledoc """
  This module defines test fixtures for Billing context.
  You can use it in your tests as:
      use Invoices.DataCase

      import Invoices.BillingFixtures
  """

  alias Invoices.Billing

  @doc """
  Generate a transaction.
  """
  def transaction_fixture(attrs \\ %{}) do
    user_id = Map.get(attrs, "user_id", Map.get(attrs, :user_id, 1))

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

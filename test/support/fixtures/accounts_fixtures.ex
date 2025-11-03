defmodule Invoices.AccountsFixtures do
  @moduledoc """
  This module defines test fixtures for Accounts context.
  """

  alias Invoices.Accounts

  @doc """
  Generate a user with a unique email.
  """
  def user_fixture(attrs \\ %{}) do
    email = attrs[:email] || "user#{System.unique_integer([:positive])}@example.com"
    password = attrs[:password] || "password12345678"

    {:ok, user} =
      Accounts.create_user(%{
        email: email,
        password: password
      })

    user
  end
end

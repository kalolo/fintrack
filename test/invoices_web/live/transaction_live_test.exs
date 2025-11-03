defmodule InvoicesWeb.TransactionLiveTest do
  use InvoicesWeb.ConnCase

  import Phoenix.LiveViewTest
  import Invoices.BillingFixtures

  @create_attrs %{
    timestamp: "2025-09-08T21:25:00",
    type: "income",
    description: "some description",
    amount: "120.5"
  }
  @update_attrs %{
    timestamp: "2025-09-09T21:25:00",
    type: "expense",
    description: "some updated description",
    amount: "456.7"
  }
  @invalid_attrs %{timestamp: nil, type: "income", description: nil, amount: nil}

  defp create_transaction(%{user: user}) do
    transaction = transaction_fixture(%{user_id: user.id})
    %{transaction: transaction}
  end

  describe "Index" do
    setup [:register_and_log_in_user, :create_transaction]

    test "lists all transactions", %{conn: conn, transaction: transaction} do
      {:ok, _index_live, html} = live(conn, ~p"/transactions")

      assert html =~ "Transactions"
      assert html =~ transaction.description
    end

    test "saves new transaction", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/transactions")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Transaction")
               |> render_click()
               |> follow_redirect(conn, ~p"/transactions/new")

      assert render(form_live) =~ "New Transaction"

      assert form_live
             |> form("#transaction-form", transaction: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#transaction-form", transaction: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/transactions")

      html = render(index_live)
      assert html =~ "Transaction created successfully"
      assert html =~ "some description"
    end

    test "updates transaction in listing", %{conn: conn, transaction: transaction} do
      {:ok, index_live, _html} = live(conn, ~p"/transactions")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#transactions-#{transaction.id} a[href='/transactions/#{transaction.id}/edit']")
               |> render_click()
               |> follow_redirect(conn, ~p"/transactions/#{transaction}/edit")

      assert render(form_live) =~ "Edit Transaction"

      assert form_live
             |> form("#transaction-form", transaction: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#transaction-form", transaction: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/transactions")

      html = render(index_live)
      assert html =~ "Transaction updated successfully"
      assert html =~ "some updated description"
    end

    test "deletes transaction in listing", %{conn: conn, transaction: transaction} do
      {:ok, index_live, _html} = live(conn, ~p"/transactions")

      assert index_live
             |> element("#transactions-#{transaction.id} a[phx-click*='delete']")
             |> render_click()

      refute has_element?(index_live, "#transactions-#{transaction.id}")
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user, :create_transaction]

    test "displays transaction", %{conn: conn, transaction: transaction} do
      {:ok, _show_live, html} = live(conn, ~p"/transactions/#{transaction}")

      assert html =~ "Transaction Details"
      assert html =~ transaction.description
    end

    test "updates transaction and returns to show", %{conn: conn, transaction: transaction} do
      {:ok, show_live, _html} = live(conn, ~p"/transactions/#{transaction}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/transactions/#{transaction}/edit?return_to=show")

      assert render(form_live) =~ "Edit Transaction"

      assert form_live
             |> form("#transaction-form", transaction: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#transaction-form", transaction: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/transactions/#{transaction}")

      html = render(show_live)
      assert html =~ "Transaction updated successfully"
      assert html =~ "some updated description"
    end
  end
end

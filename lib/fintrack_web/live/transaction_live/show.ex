defmodule FinTrackWeb.TransactionLive.Show do
  use FinTrackWeb, :live_view

  alias FinTrack.Billing

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.header>
        Transaction Details
        <:subtitle>
          <span class={[
            "px-2 py-1 rounded text-sm font-medium",
            @transaction.type == "income" && "bg-green-100 text-green-800",
            @transaction.type == "expense" && "bg-red-100 text-red-800"
          ]}>
            {String.capitalize(@transaction.type)}
          </span>
        </:subtitle>
        <:actions>
          <.link navigate={~p"/transactions"}>
            <.button>Back to Transactions</.button>
          </.link>
          <.link navigate={~p"/transactions/#{@transaction}/edit?return_to=show"}>
            <.button>Edit Transaction</.button>
          </.link>
        </:actions>
      </.header>

      <div class="max-w-2xl mx-auto">
        <.list>
          <:item title="Type">
            <span class={[
              "px-2 py-1 rounded text-sm font-medium",
              @transaction.type == "income" && "bg-green-100 text-green-800",
              @transaction.type == "expense" && "bg-red-100 text-red-800"
            ]}>
              {String.capitalize(@transaction.type)}
            </span>
          </:item>
          <:item title="Amount">
            <span class={[
              "font-medium text-lg",
              @transaction.type == "income" && "text-green-600",
              @transaction.type == "expense" && "text-red-600"
            ]}>
              {format_currency(@transaction.amount)}
            </span>
          </:item>
          <:item title="Description">{@transaction.description}</:item>
          <:item title="Payment Method">
            <span class="px-2 py-1 rounded text-sm font-medium bg-gray-100 text-gray-800">
              {FinTrack.Billing.Transaction.payment_method_display(@transaction.payment_method)}
            </span>
          </:item>
          <:item title="Date & Time">
            {Calendar.strftime(@transaction.timestamp, "%B %d, %Y at %I:%M %p")}
          </:item>
        </.list>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Show Transaction")
     |> assign(:transaction, Billing.get_transaction!(id))}
  end
end

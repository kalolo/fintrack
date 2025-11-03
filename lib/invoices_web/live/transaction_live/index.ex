defmodule InvoicesWeb.TransactionLive.Index do
  use InvoicesWeb, :live_view

  alias Invoices.Billing

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.header>
        Transactions
        <:actions>
          <div class="flex items-center space-x-4">
            <form phx-submit="apply_sort" class="flex items-center space-x-2">
              <select
                name="sort_by"
                id="sort-by-select"
                class="border border-gray-300 rounded-md px-3 py-2 text-sm"
              >
                <option value="timestamp" selected={@sort_by == "timestamp"}>Date</option>
                <option value="type" selected={@sort_by == "type"}>Type</option>
                <option value="amount" selected={@sort_by == "amount"}>Amount</option>
                <option value="description" selected={@sort_by == "description"}>Description</option>
                <option value="payment_method" selected={@sort_by == "payment_method"}>
                  Payment Method
                </option>
              </select>

              <select
                name="sort_order"
                id="sort-order-select"
                class="border border-gray-300 rounded-md px-3 py-2 text-sm"
              >
                <option value="asc" selected={@sort_order == "asc"}>Ascending</option>
                <option value="desc" selected={@sort_order == "desc"}>Descending</option>
              </select>

              <.button
                type="submit"
                class="bg-gray-500 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded text-sm"
              >
                Apply
              </.button>
            </form>

            <.link navigate={~p"/transactions/new"}>
              <.button>New Transaction</.button>
            </.link>
          </div>
        </:actions>
      </.header>

      <.table
        id="transactions"
        rows={@streams.transactions}
        row_click={fn {_id, transaction} -> JS.navigate(~p"/transactions/#{transaction}") end}
      >
        <:col :let={{_id, transaction}} label="Date">
          {Calendar.strftime(transaction.timestamp, "%B %d %Y")}
        </:col>
        <:col :let={{_id, transaction}} label="Type">
          <span class={[
            "px-2 py-1 rounded text-sm font-medium",
            transaction.type == "income" && "bg-green-100 text-green-800",
            transaction.type == "expense" && "bg-red-100 text-red-800"
          ]}>
            {String.capitalize(transaction.type)}
          </span>
        </:col>
        <:col :let={{_id, transaction}} label="Description">{transaction.description}</:col>
        <:col :let={{_id, transaction}} label="Payment Method">
          <span class="px-2 py-1 rounded text-xs font-medium bg-gray-100 text-gray-800">
            {Invoices.Billing.Transaction.payment_method_display(transaction.payment_method)}
          </span>
        </:col>
        <:col :let={{_id, transaction}} label="Amount">
          <span class={[
            "font-medium",
            transaction.type == "income" && "text-green-600",
            transaction.type == "expense" && "text-red-600"
          ]}>
            {format_currency(transaction.amount)}
          </span>
        </:col>
        <:action :let={{_id, transaction}}>
          <div class="sr-only">
            <.link navigate={~p"/transactions/#{transaction}"}>Show</.link>
          </div>
          <.link navigate={~p"/transactions/#{transaction}"} title="View Transaction">
            <button class="bg-green-500 hover:bg-green-700 text-white font-bold py-1 px-2 rounded text-sm">
              <i class="fas fa-eye"></i>
            </button>
          </.link>
        </:action>
        <:action :let={{_id, transaction}}>
          <.link navigate={~p"/transactions/#{transaction}/edit"} title="Edit Transaction">
            <button class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-2 rounded text-sm">
              <i class="fas fa-edit"></i>
            </button>
          </.link>
        </:action>
        <:action :let={{id, transaction}}>
          <.link
            phx-click={JS.push("delete", value: %{id: transaction.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
            title="Delete Transaction"
            class="bg-red-500 hover:bg-red-700 text-white font-bold py-1 px-2 rounded text-sm inline-block"
          >
            <i class="fas fa-trash"></i>
          </.link>
        </:action>
      </.table>
      
    <!-- Pagination -->
      <div class="mt-6 flex items-center justify-between">
        <div class="flex-1 flex justify-between sm:hidden">
          <%= if @page_info.page_number > 1 do %>
            <.link
              patch={
                ~p"/transactions?page=#{@page_info.page_number - 1}&sort_by=#{@sort_by}&sort_order=#{@sort_order}"
              }
              class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              Previous
            </.link>
          <% else %>
            <span class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-400 bg-gray-100 cursor-not-allowed">
              Previous
            </span>
          <% end %>

          <%= if @page_info.page_number < @page_info.total_pages do %>
            <.link
              patch={
                ~p"/transactions?page=#{@page_info.page_number + 1}&sort_by=#{@sort_by}&sort_order=#{@sort_order}"
              }
              class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              Next
            </.link>
          <% else %>
            <span class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-400 bg-gray-100 cursor-not-allowed">
              Next
            </span>
          <% end %>
        </div>
        
    <!-- Desktop pagination -->
        <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
          <div>
            <p class="text-sm text-gray-700">
              Showing
              <span class="font-medium">
                {(@page_info.page_number - 1) * @page_info.page_size + 1}
              </span>
              to
              <span class="font-medium">
                {min(@page_info.page_number * @page_info.page_size, @page_info.total_entries)}
              </span>
              of <span class="font-medium">{@page_info.total_entries}</span>
              results
            </p>
          </div>
          <div>
            <nav
              class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px"
              aria-label="Pagination"
            >
              <!-- Previous button -->
              <%= if @page_info.page_number > 1 do %>
                <.link
                  patch={
                    ~p"/transactions?page=#{@page_info.page_number - 1}&sort_by=#{@sort_by}&sort_order=#{@sort_order}"
                  }
                  class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                >
                  <span class="sr-only">Previous</span>
                  <.icon name="hero-chevron-left" class="h-5 w-5" />
                </.link>
              <% else %>
                <span class="relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-gray-100 text-sm font-medium text-gray-400 cursor-not-allowed">
                  <span class="sr-only">Previous</span>
                  <.icon name="hero-chevron-left" class="h-5 w-5" />
                </span>
              <% end %>
              
    <!-- Page numbers -->
              <%= for page <- pagination_range(@page_info) do %>
                <%= if page == @page_info.page_number do %>
                  <span class="relative inline-flex items-center px-4 py-2 border border-teal-500 bg-teal-50 text-sm font-medium text-teal-600">
                    {page}
                  </span>
                <% else %>
                  <.link
                    patch={
                      ~p"/transactions?page=#{page}&sort_by=#{@sort_by}&sort_order=#{@sort_order}"
                    }
                    class="relative inline-flex items-center px-4 py-2 border border-gray-300 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50"
                  >
                    {page}
                  </.link>
                <% end %>
              <% end %>
              
    <!-- Next button -->
              <%= if @page_info.page_number < @page_info.total_pages do %>
                <.link
                  patch={
                    ~p"/transactions?page=#{@page_info.page_number + 1}&sort_by=#{@sort_by}&sort_order=#{@sort_order}"
                  }
                  class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium text-gray-500 hover:bg-gray-50"
                >
                  <span class="sr-only">Next</span>
                  <.icon name="hero-chevron-right" class="h-5 w-5" />
                </.link>
              <% else %>
                <span class="relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-gray-100 text-sm font-medium text-gray-400 cursor-not-allowed">
                  <span class="sr-only">Next</span>
                  <.icon name="hero-chevron-right" class="h-5 w-5" />
                </span>
              <% end %>
            </nav>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = String.to_integer(params["page"] || "1")
    sort_by = params["sort_by"] || "timestamp"
    sort_order = params["sort_order"] || "desc"

    query_params = %{
      "page" => page,
      "sort_by" => sort_by,
      "sort_order" => sort_order
    }

    paginated_transactions =
      Billing.list_transactions_for_user(socket.assigns.current_user.id, query_params)

    {:noreply,
     socket
     |> stream(:transactions, paginated_transactions.entries, reset: true)
     |> assign(:page_info, paginated_transactions)
     |> assign(:sort_by, sort_by)
     |> assign(:sort_order, sort_order)
     |> assign(:page_title, "Transactions")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    transaction = Billing.get_transaction!(id)
    {:ok, _} = Billing.delete_transaction(transaction)

    {:noreply, stream_delete(socket, :transactions, transaction)}
  end

  @impl true
  def handle_event("apply_sort", %{"sort_by" => sort_by, "sort_order" => sort_order}, socket) do
    {:noreply,
     push_patch(socket, to: ~p"/transactions?sort_by=#{sort_by}&sort_order=#{sort_order}")}
  end

  defp pagination_range(page_info) do
    current_page = page_info.page_number
    total_pages = page_info.total_pages

    # Show up to 5 pages around the current page
    start_page = max(1, current_page - 2)
    end_page = min(total_pages, current_page + 2)

    # Adjust range to always show 5 pages when possible
    {start_page, end_page} =
      if end_page - start_page < 4 do
        if start_page == 1 do
          {start_page, min(total_pages, start_page + 4)}
        else
          {max(1, end_page - 4), end_page}
        end
      else
        {start_page, end_page}
      end

    start_page..end_page
  end
end

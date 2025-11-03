defmodule InvoicesWeb.InvoiceLive.Index do
  use InvoicesWeb, :live_view

  alias Invoices.Billing
  alias Invoices.Billing.Invoice

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    page = String.to_integer(params["page"] || "1")
    sort_by = params["sort_by"] || "invoice_number"
    sort_order = params["sort_order"] || "desc"

    query_params = %{
      "page" => page,
      "sort_by" => sort_by,
      "sort_order" => sort_order
    }

    paginated_invoices =
      Billing.list_invoices_for_user(socket.assigns.current_user.id, query_params)

    {:noreply,
     socket
     |> stream(:invoices, paginated_invoices.entries, reset: true)
     |> assign(:page_info, paginated_invoices)
     |> assign(:sort_by, sort_by)
     |> assign(:sort_order, sort_order)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Invoice")
    |> assign(:invoice, %Invoice{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Invoice")
    |> assign(:invoice, Billing.get_invoice!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Invoices")
    |> assign(:invoice, nil)
  end

  @impl true
  def handle_info({InvoicesWeb.InvoiceLive.FormComponent, {:saved, invoice}}, socket) do
    case socket.assigns.live_action do
      :new ->
        {:noreply, stream_insert(socket, :invoices, invoice, at: 0)}

      :edit ->
        {:noreply, stream_insert(socket, :invoices, invoice)}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    invoice = Billing.get_invoice!(id)
    {:ok, _} = Billing.delete_invoice(invoice)

    {:noreply, stream_delete(socket, :invoices, invoice)}
  end

  @impl true
  def handle_event("apply_sort", %{"sort_by" => sort_by, "sort_order" => sort_order}, socket) do
    {:noreply, push_patch(socket, to: ~p"/?sort_by=#{sort_by}&sort_order=#{sort_order}")}
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

defmodule InvoicesWeb.InvoiceLive.Show do
  use InvoicesWeb, :live_view

  alias Invoices.Billing

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    invoice = Billing.get_invoice!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Invoice #{invoice.invoice_number}")
     |> assign(:invoice, invoice)
     |> assign(:client_info, Billing.get_client_info())
     |> assign(:bill_to_info, Billing.get_bill_to_info())}
  end

  @impl true
  def handle_event("generate_pdf", %{"id" => id}, socket) do
    # Instead of generating PDF locally, we'll open the PDF route
    pdf_url = ~p"/invoices/#{id}/pdf"

    {:noreply,
     socket
     |> put_flash(:info, "Opening PDF in new tab...")
     |> push_event("open_pdf", %{url: pdf_url})}
  end
end

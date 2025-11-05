defmodule FinTrackWeb.InvoiceLive.FormComponent do
  use FinTrackWeb, :live_component

  alias FinTrack.Billing

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>
          Use this form to {(@action == :edit && "update") || "create"} an invoice.
        </:subtitle>
      </.header>

      <.form
        for={@form}
        id="invoice-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:description]} type="text" label="Description" />
        <.input field={@form[:amount]} type="number" label="Amount" step="0.01" />
        <.input field={@form[:date]} type="date" label="Date (optional)" />

        <div class="mt-4">
          <.button phx-disable-with="Saving...">Save Invoice</.button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{invoice: invoice} = assigns, socket) do
    changeset = Billing.change_invoice(invoice)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"invoice" => invoice_params}, socket) do
    changeset =
      socket.assigns.invoice
      |> Billing.change_invoice(invoice_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"invoice" => invoice_params}, socket) do
    save_invoice(socket, socket.assigns.action, invoice_params)
  end

  defp save_invoice(socket, :new, invoice_params) do
    case Billing.create_invoice(invoice_params, socket.assigns.current_user.id) do
      {:ok, invoice} ->
        # Create corresponding income transaction
        case Billing.create_income_transaction_from_invoice(
               invoice,
               socket.assigns.current_user.id
             ) do
          {:ok, _transaction} ->
            notify_parent({:saved, invoice})

            {:noreply,
             socket
             |> put_flash(:info, "Invoice and income transaction created successfully")
             |> push_patch(to: socket.assigns.patch)}

          {:error, _changeset} ->
            # Invoice was created but transaction failed - still show success but with warning
            notify_parent({:saved, invoice})

            {:noreply,
             socket
             |> put_flash(
               :info,
               "Invoice created successfully, but income transaction failed to create"
             )
             |> push_patch(to: socket.assigns.patch)}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_invoice(socket, :edit, invoice_params) do
    case Billing.update_invoice(socket.assigns.invoice, invoice_params) do
      {:ok, invoice} ->
        notify_parent({:saved, invoice})

        {:noreply,
         socket
         |> put_flash(:info, "Invoice updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

defmodule FinTrackWeb.TransactionLive.Form do
  use FinTrackWeb, :live_view

  alias FinTrack.Billing
  alias FinTrack.Billing.Transaction

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.header>
        {@page_title}
        <:subtitle>Use this form to manage transaction records.</:subtitle>
      </.header>

      <div class="max-w-md mx-auto">
        <.form for={@form} id="transaction-form" phx-change="validate" phx-submit="save">
          <.input
            field={@form[:type]}
            type="select"
            label="Type"
            options={[{"Income", "income"}, {"Expense", "expense"}]}
            required
          />
          <.input field={@form[:amount]} type="number" label="Amount" step="0.01" required />
          <.input field={@form[:description]} type="text" label="Description" required />
          <.input
            field={@form[:payment_method]}
            type="select"
            label="Payment Method"
            options={Transaction.payment_method_options()}
            required
          />
          <.input
            field={@form[:timestamp]}
            type="datetime-local"
            label="Date & Time (optional)"
          />

          <div class="mt-6 flex items-center justify-end space-x-3">
            <.link
              navigate={return_path(@return_to, @transaction)}
              class="text-sm font-semibold leading-6 text-gray-900 hover:text-gray-700"
            >
              Cancel
            </.link>
            <.button phx-disable-with="Saving...">Save Transaction</.button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    transaction = Billing.get_transaction!(id)

    socket
    |> assign(:page_title, "Edit Transaction")
    |> assign(:transaction, transaction)
    |> assign(:form, to_form(Billing.change_transaction(transaction)))
  end

  defp apply_action(socket, :new, _params) do
    transaction = %Transaction{}

    socket
    |> assign(:page_title, "New Transaction")
    |> assign(:transaction, transaction)
    |> assign(:form, to_form(Billing.change_transaction(transaction)))
  end

  @impl true
  def handle_event("validate", %{"transaction" => transaction_params}, socket) do
    changeset = Billing.change_transaction(socket.assigns.transaction, transaction_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"transaction" => transaction_params}, socket) do
    save_transaction(socket, socket.assigns.live_action, transaction_params)
  end

  defp save_transaction(socket, :edit, transaction_params) do
    case Billing.update_transaction(socket.assigns.transaction, transaction_params) do
      {:ok, transaction} ->
        {:noreply,
         socket
         |> put_flash(:info, "Transaction updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, transaction))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_transaction(socket, :new, transaction_params) do
    case Billing.create_transaction(transaction_params, socket.assigns.current_user.id) do
      {:ok, transaction} ->
        {:noreply,
         socket
         |> put_flash(:info, "Transaction created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, transaction))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _transaction), do: ~p"/transactions"
  defp return_path("show", transaction), do: ~p"/transactions/#{transaction}"
end

defmodule FinTrackWeb.InvestmentLive.Index do
  use FinTrackWeb, :live_view
  import FinTrackWeb.CoreComponents
  alias FinTrack.Investments

  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    investments = Investments.list_investments_for_user(user_id)
    comparison_chart_data = prepare_comparison_chart_data(investments)
    total_in_investments = Investments.total_in_investments(user_id)

    {:ok,
     assign(socket,
       investments: investments,
       comparison_chart_data: comparison_chart_data,
       show_modal: false,
       modal_action: nil,
       new_investment_form:
         to_form(Investments.Investment.changeset(%Investments.Investment{}, %{})),
       value_capture_form: nil,
       selected_investment: nil,
       chart_labels: [],
       chart_data: [],
       show_value_captures_modal: false,
       value_captures: [],
       edit_value_capture_form: nil,
       editing_value_capture_id: nil,
       total_in_investments: total_in_investments
     )}
  end

  def handle_event("show_add_investment", _params, socket) do
    changeset = Investments.Investment.changeset(%Investments.Investment{}, %{})

    {:noreply,
     assign(socket, show_modal: true, modal_action: :add, new_investment_form: to_form(changeset))}
  end

  def handle_event("hide_modal", _params, socket) do
    {:noreply,
     assign(socket,
       show_modal: false,
       modal_action: nil,
       new_investment_form:
         to_form(Investments.Investment.changeset(%Investments.Investment{}, %{})),
       value_capture_form: nil
     )}
  end

  def handle_event("add_investment", %{"investment" => params}, socket) do
    user_id = socket.assigns.current_user.id

    case Investments.create_investment(params, user_id) do
      {:ok, _inv} ->
        investments = Investments.list_investments_for_user(user_id)
        comparison_chart_data = prepare_comparison_chart_data(investments)

        {:noreply,
         assign(socket,
           investments: investments,
           comparison_chart_data: comparison_chart_data,
           show_modal: false
         )}

      {:error, changeset} ->
        {:noreply,
         assign(socket,
           new_investment_form: to_form(changeset),
           show_modal: true,
           modal_action: :add
         )}
    end
  end

  def handle_event("show_add_value_capture", %{"id" => investment_id}, socket) do
    vc_changeset =
      Investments.ValueCapture.changeset(%Investments.ValueCapture{}, %{
        captured_at: Date.utc_today()
      })

    {:noreply,
     assign(socket,
       show_modal: true,
       modal_action: :add_value_capture,
       selected_investment: String.to_integer(investment_id),
       value_capture_form: to_form(vc_changeset)
     )}
  end

  def handle_event("add_value_capture", %{"value_capture" => params}, socket) do
    investment_id = socket.assigns.selected_investment

    case Investments.add_value_capture(investment_id, params) do
      {:ok, _} ->
        user_id = socket.assigns.current_user.id
        investments = Investments.list_investments_for_user(user_id)
        comparison_chart_data = prepare_comparison_chart_data(investments)

        {:noreply,
         assign(socket,
           investments: investments,
           comparison_chart_data: comparison_chart_data,
           show_modal: false,
           value_capture_form: nil,
           selected_investment: nil
         )}

      {:error, changeset} ->
        {:noreply,
         assign(socket,
           value_capture_form: to_form(changeset),
           show_modal: true,
           modal_action: :add_value_capture
         )}
    end
  end

  def handle_event("show_chart", %{"id" => id}, socket) do
    inv = Enum.find(socket.assigns.investments, &("#{&1.id}" == id))

    sorted_captures =
      inv.value_captures
      |> Enum.sort_by(& &1.captured_at)
      |> Enum.map(fn capture ->
        %{
          captured_at: Date.to_string(capture.captured_at),
          value: Decimal.to_float(capture.value)
        }
      end)

    # data =
    #   sorted_captures
    #   |> Enum.reduce([], fn %{value: value, captured_at: date}, acc ->
    #     IO.inspect(value, label: "Value on #{date}")
    #     [Decimal.to_float(value) | acc]
    #   end)
    #   |> Enum.reverse()

    # IO.inspect(data)

    {:noreply,
     assign(socket,
       chart_captures: sorted_captures,
       show_chart_modal: true,
       chart_inv_name: inv.name
     )}
  end

  def handle_event("hide_chart", _params, socket) do
    {:noreply, assign(socket, show_chart_modal: false)}
  end

  def handle_event("show_value_captures", %{"id" => investment_id}, socket) do
    investment_id = String.to_integer(investment_id)
    inv = Enum.find(socket.assigns.investments, &(&1.id == investment_id))
    value_captures = Enum.sort_by(inv.value_captures, & &1.captured_at, Date)

    {:noreply,
     assign(socket,
       show_value_captures_modal: true,
       selected_investment: inv,
       value_captures: value_captures,
       edit_value_capture_form: nil,
       editing_value_capture_id: nil
     )}
  end

  def handle_event("hide_value_captures", _params, socket) do
    {:noreply,
     assign(socket,
       show_value_captures_modal: false,
       selected_investment: nil,
       value_captures: [],
       edit_value_capture_form: nil,
       editing_value_capture_id: nil
     )}
  end

  def handle_event("edit_value_capture", %{"id" => value_capture_id}, socket) do
    value_capture_id = String.to_integer(value_capture_id)
    value_capture = Investments.get_value_capture!(value_capture_id)
    changeset = Investments.ValueCapture.changeset(value_capture, %{})

    {:noreply,
     assign(socket,
       edit_value_capture_form: to_form(changeset),
       editing_value_capture_id: value_capture_id
     )}
  end

  def handle_event("cancel_edit_value_capture", _params, socket) do
    {:noreply,
     assign(socket,
       edit_value_capture_form: nil,
       editing_value_capture_id: nil
     )}
  end

  def handle_event("update_value_capture", %{"value_capture" => params}, socket) do
    value_capture = Investments.get_value_capture!(socket.assigns.editing_value_capture_id)

    case Investments.update_value_capture(value_capture, params) do
      {:ok, _updated_vc} ->
        # Refresh the data
        user_id = socket.assigns.current_user.id
        investments = Investments.list_investments_for_user(user_id)
        comparison_chart_data = prepare_comparison_chart_data(investments)

        # Update the value captures for the modal
        inv = Enum.find(investments, &(&1.id == socket.assigns.selected_investment.id))
        value_captures = Enum.sort_by(inv.value_captures, & &1.captured_at)

        {:noreply,
         assign(socket,
           investments: investments,
           comparison_chart_data: comparison_chart_data,
           selected_investment: inv,
           value_captures: value_captures,
           edit_value_capture_form: nil,
           editing_value_capture_id: nil
         )}

      {:error, changeset} ->
        {:noreply,
         assign(socket,
           edit_value_capture_form: to_form(changeset)
         )}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash}>
      <.header>
        <div class="text-lg md:text-xl">💹 Investments & ROI Tracking</div>
        <:actions>
          <.button
            id="add-investment-btn"
            phx-click="show_add_investment"
            class="bg-green-600 hover:bg-green-800 text-white font-bold px-3 md:px-5 py-2 rounded text-sm md:text-base"
          >
            <span class="md:hidden">+</span>
            <span class="hidden md:inline">+ Add Investment</span>
          </.button>
        </:actions>
      </.header>
      <!-- Key Metrics Card -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <div class="bg-green-50 p-6 rounded-lg shadow">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <.icon name="hero-chart-bar" class="text-blue-500 w-8 h-8" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-green-600">Total Portfolio Value</p>
              <p class="text-2xl font-bold text-green-900">
                {@total_in_investments |> format_currency()}
              </p>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Investments Comparison Chart -->
      <%= if not Enum.empty?(@investments) do %>
        <div class="mt-7 bg-white p-4 md:p-6 rounded-lg shadow">
          <h3 class="text-base md:text-lg font-semibold text-gray-900 mb-4">
            Investment Performance Comparison
          </h3>
          <div class="w-full h-64 md:h-96 bg-gray-50 rounded-lg p-2 md:p-4">
            <canvas
              id="investmentsComparisonChart"
              phx-hook="InvestmentsComparisonChart"
              data-chart-data={Jason.encode!(@comparison_chart_data)}
              class="w-full h-full"
              style="max-height: 350px;"
            />
          </div>
        </div>
      <% end %>

      <div class="mt-7 flex flex-col space-y-8">
        <!-- Desktop Table View -->
        <div class="hidden md:block">
          <table class="min-w-full divide-y divide-gray-200 shadow rounded-lg overflow-hidden">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Investment
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Initial Value
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Previous Value
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Latest Value
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Change (%)
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-100">
              <%= for inv <- @investments do %>
                <tr>
                  <td class="px-6 py-4 font-bold">{inv.name}</td>
                  <td class="px-6 py-4">{format_currency(inv.initial_value)}</td>
                  <td class="px-6 py-4">
                    {format_currency(FinTrack.Investments.Investment.previous_value(inv))}
                  </td>
                  <td class="px-6 py-4">
                    <%= if length(inv.value_captures) > 0 do %>
                      {format_currency(FinTrack.Investments.Investment.latest_value(inv))}
                    <% else %>
                      --
                    <% end %>
                  </td>
                  <td class="px-6 py-4">
                    <%= if length(inv.value_captures) > 0 do %>
                      <% previous = FinTrack.Investments.Investment.previous_value(inv) %>
                      <% latest = FinTrack.Investments.Investment.latest_value(inv) %>
                      <% change = if previous == 0, do: 0, else: (latest - previous) / previous * 100 %>
                      <span class={[
                        change > 0 && "text-green-600 font-semibold",
                        change < 0 && "text-red-600 font-semibold",
                        change == 0 && "text-gray-800"
                      ]}>
                        {format_currency(latest - previous)} ( {:erlang.float_to_binary(change, [
                          :compact,
                          {:decimals, 2}
                        ])}% )
                      </span>
                    <% else %>
                      --
                    <% end %>
                  </td>
                  <td class="px-6 py-4 flex gap-2 items-center">
                    <.button
                      phx-click="show_add_value_capture"
                      phx-value-id={inv.id}
                      class="p-2 bg-blue-100 hover:bg-blue-200 text-blue-800 rounded-full transition-colors"
                      title="Add Value"
                    >
                      <.icon name="hero-plus" class="w-4 h-4" />
                    </.button>
                    <.button
                      phx-click="show_value_captures"
                      phx-value-id={inv.id}
                      class="p-2 bg-purple-100 hover:bg-purple-200 text-purple-800 rounded-full transition-colors"
                      title="View Values"
                    >
                      <.icon name="hero-eye" class="w-4 h-4" />
                    </.button>
                    <.button
                      phx-click="show_chart"
                      phx-value-id={inv.id}
                      class="p-2 bg-yellow-100 hover:bg-yellow-200 text-yellow-800 rounded-full transition-colors"
                      title="ROI Chart"
                    >
                      <.icon name="hero-chart-bar" class="w-4 h-4" />
                    </.button>
                  </td>
                </tr>
              <% end %>
              <% total_previous_value =
                @investments
                |> Enum.filter(&(length(&1.value_captures) > 0))
                |> Enum.map(&FinTrack.Investments.Investment.previous_value(&1))
                |> Enum.reduce(0, &(&1 + &2)) %>
              <% total_latest_value =
                @investments
                |> Enum.filter(&(length(&1.value_captures) > 0))
                |> Enum.map(&FinTrack.Investments.Investment.latest_value(&1))
                |> Enum.reduce(0, &(&1 + &2)) %>
              <% total_change =
                @investments
                |> Enum.filter(&(length(&1.value_captures) > 0))
                |> Enum.map(fn inv ->
                  previous = FinTrack.Investments.Investment.previous_value(inv)
                  latest = FinTrack.Investments.Investment.latest_value(inv)
                  latest - previous
                end)
                |> Enum.reduce(0, &(&1 + &2)) %>
              <tr class="bg-gray-100 font-bold border-t-2 border-gray-300">
                <td class="px-6 py-4">Total</td>
                <td class="px-6 py-4"></td>
                <td class="px-6 py-4">{format_currency(total_previous_value)}</td>
                <td class="px-6 py-4">{format_currency(total_latest_value)}</td>
                <td class="px-6 py-4">
                  <span class={[
                    total_change > 0 && "text-green-600",
                    total_change < 0 && "text-red-600",
                    total_change == 0 && "text-gray-800"
                  ]}>
                    {format_currency(total_change)}
                  </span>
                </td>
                <td class="px-6 py-4"></td>
              </tr>
            </tbody>
          </table>
        </div>
        
    <!-- Changes by Date Table -->
        <%= if not Enum.empty?(@investments) do %>
          <% changes_by_date = calculate_changes_by_date(@investments) %>
          <%= if not Enum.empty?(changes_by_date) do %>
            <div class="mt-8">
              <h3 class="text-lg font-semibold text-gray-900 mb-4">Changes by Capture Date</h3>
              <div class="bg-white shadow rounded-lg overflow-hidden">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Date
                      </th>
                      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        Change
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-gray-100">
                    <%= for {date, change} <- changes_by_date do %>
                      <tr>
                        <td class="px-6 py-4 text-sm text-gray-900">
                          {Date.to_string(date)}
                        </td>
                        <td class="px-6 py-4 text-sm">
                          <span class={[
                            "font-semibold",
                            change > 0 && "text-green-600",
                            change < 0 && "text-red-600",
                            change == 0 && "text-gray-800"
                          ]}>
                            {format_currency(change)}
                          </span>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          <% end %>
        <% end %>
        
    <!-- Mobile Card View -->
        <div class="md:hidden space-y-4">
          <%= for inv <- @investments do %>
            <div class="bg-white rounded-lg shadow-md p-4 space-y-3">
              <div class="flex justify-between items-start">
                <h3 class="font-bold text-lg text-gray-900">{inv.name}</h3>
                <%= if length(inv.value_captures) > 0 do %>
                  <% start = Decimal.to_float(inv.initial_value) %>
                  <% sorted_captures = Enum.sort_by(inv.value_captures, & &1.captured_at) %>
                  <% latest = Decimal.to_float(List.last(sorted_captures).value) %>
                  <% change = if start == 0, do: 0, else: (latest - start) / start * 100 %>
                  <span class={[
                    "px-2 py-1 rounded-full text-sm font-semibold",
                    change > 0 && "bg-green-100 text-green-800",
                    change < 0 && "bg-red-100 text-red-800",
                    change == 0 && "bg-gray-100 text-gray-800"
                  ]}>
                    {:erlang.float_to_binary(change, [:compact, {:decimals, 2}])}%
                  </span>
                <% end %>
              </div>

              <div class="grid grid-cols-2 gap-4 text-sm">
                <div>
                  <span class="text-gray-500">Initial:</span>
                  <div class="font-semibold">{format_currency(inv.initial_value)}</div>
                </div>
                <div>
                  <span class="text-gray-500">Latest:</span>
                  <div class="font-semibold">
                    <%= if length(inv.value_captures) > 0 do %>
                      <% sorted_captures = Enum.sort_by(inv.value_captures, & &1.captured_at) %>
                      {format_currency(List.last(sorted_captures).value)}
                    <% else %>
                      --
                    <% end %>
                  </div>
                </div>
              </div>

              <div class="flex gap-2 justify-center pt-2">
                <.button
                  phx-click="show_add_value_capture"
                  phx-value-id={inv.id}
                  class="flex-1 bg-blue-100 hover:bg-blue-200 text-blue-800 px-3 py-2 rounded-lg transition-colors text-sm font-medium"
                >
                  <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Add
                </.button>
                <.button
                  phx-click="show_value_captures"
                  phx-value-id={inv.id}
                  class="flex-1 bg-purple-100 hover:bg-purple-200 text-purple-800 px-3 py-2 rounded-lg transition-colors text-sm font-medium"
                >
                  <.icon name="hero-eye" class="w-4 h-4 mr-1" /> View
                </.button>
                <.button
                  phx-click="show_chart"
                  phx-value-id={inv.id}
                  class="flex-1 bg-yellow-100 hover:bg-yellow-200 text-yellow-800 px-3 py-2 rounded-lg transition-colors text-sm font-medium"
                >
                  <.icon name="hero-chart-bar" class="w-4 h-4 mr-1" /> Chart
                </.button>
              </div>
            </div>
          <% end %>
        </div>

        <%= if @show_modal && @modal_action == :add do %>
          <.modal id="inv-add-modal" on_cancel="hide_modal">
            <h3 class="text-lg font-medium mb-4">Add New Investment</h3>
            <.form for={@new_investment_form} phx-submit="add_investment">
              <.input field={@new_investment_form[:name]} label="Name" required />
              <.input
                field={@new_investment_form[:initial_value]}
                label="Initial Value"
                type="number"
                step="0.01"
                required
              />
              <div class="mt-6 flex gap-3">
                <.button
                  type="submit"
                  class="bg-green-600 hover:bg-green-800 text-white px-6 py-2 rounded"
                >
                  Add
                </.button>
                <.button type="button" phx-click="hide_modal" class="bg-gray-300">Cancel</.button>
              </div>
            </.form>
          </.modal>
        <% end %>

        <%= if @show_modal && @modal_action == :add_value_capture do %>
          <.modal id="vc-add-modal" on_cancel="hide_modal">
            <div class="space-y-6">
              <!-- Modal Header -->
              <div class="flex items-center space-x-3">
                <div class="flex-shrink-0">
                  <.icon name="hero-chart-bar" class="w-8 h-8 text-blue-600" />
                </div>
                <div>
                  <h3 class="text-xl font-semibold text-gray-900">Add Value Capture</h3>
                  <p class="text-sm text-gray-600">Record the current value of your investment</p>
                </div>
              </div>
              
    <!-- Form Section -->
              <div class="bg-gray-50 rounded-lg p-4">
                <.form for={@value_capture_form} phx-submit="add_value_capture" class="space-y-4">
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <.input
                      type="date"
                      field={@value_capture_form[:captured_at]}
                      label="Capture Date"
                      required
                      class="w-full"
                    />
                    <.input
                      type="number"
                      step="0.01"
                      field={@value_capture_form[:value]}
                      label="Current Value ($)"
                      required
                      class="w-full"
                      placeholder="Enter current value"
                    />
                  </div>
                  
    <!-- Action Buttons -->
                  <div class="flex flex-col sm:flex-row gap-3 pt-4 border-t border-gray-200">
                    <.button
                      type="submit"
                      class="flex-1 sm:flex-none bg-blue-600 hover:bg-blue-700 text-white font-semibold px-6 py-2.5 rounded-lg transition-colors duration-200 flex items-center justify-center space-x-2"
                    >
                      <.icon name="hero-plus" class="w-4 h-4" />
                      <span>Save Value Capture</span>
                    </.button>
                    <.button
                      type="button"
                      phx-click="hide_modal"
                      class="flex-1 sm:flex-none bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium px-6 py-2.5 rounded-lg border border-gray-300 transition-colors duration-200"
                    >
                      Cancel
                    </.button>
                  </div>
                </.form>
              </div>
            </div>
          </.modal>
        <% end %>

        <%= if assigns[:show_chart_modal] do %>
          <div
            id="roi-chart-modal"
            class="fixed inset-0 z-40 overflow-y-auto bg-black/20 flex items-center justify-center p-2 md:p-4"
            tabindex="-1"
            role="dialog"
            aria-modal="true"
          >
            <div class="relative bg-white rounded-lg shadow-lg w-full max-w-4xl max-h-[90vh] flex flex-col">
              <div class="flex items-center px-4 md:px-6 py-3 md:py-4 border-b">
                <h3 class="text-base md:text-lg font-bold flex-1 truncate">
                  ROI Chart for {@chart_inv_name}
                </h3>
                <button
                  type="button"
                  class="text-gray-500 hover:text-gray-700 ml-2 p-1"
                  phx-click="hide_chart"
                  aria-label="Close"
                >
                  <.icon name="hero-x-mark" class="w-5 h-5" />
                </button>
              </div>
              <div class="px-4 md:px-6 py-4 md:py-6 flex-1 overflow-hidden">
                <div class="w-full h-64 md:h-96 bg-gray-50 rounded-lg p-2 md:p-4">
                  <canvas
                    id="roiChart"
                    phx-hook="RoiChart"
                    data-chart-data={Jason.encode!(@chart_captures)}
                    class="w-full h-full"
                    style="max-height: 350px;"
                  />
                </div>
              </div>
            </div>
          </div>
        <% end %>

        <%= if assigns[:show_value_captures_modal] do %>
          <div
            id="value-captures-modal"
            class="fixed inset-0 z-40 overflow-y-auto bg-black/20 flex items-center justify-center p-2 md:p-4"
            tabindex="-1"
            role="dialog"
            aria-modal="true"
          >
            <div class="relative bg-white rounded-lg shadow-lg w-full max-w-4xl max-h-[90vh] flex flex-col">
              <div class="flex items-center px-4 md:px-6 py-3 md:py-4 border-b">
                <h3 class="text-base md:text-lg font-bold flex-1 truncate">
                  Value Captures for {@selected_investment.name}
                </h3>
                <button
                  type="button"
                  class="text-gray-500 hover:text-gray-700 ml-2 p-1"
                  phx-click="hide_value_captures"
                  aria-label="Close"
                >
                  <.icon name="hero-x-mark" class="w-5 h-5" />
                </button>
              </div>
              <div class="px-4 md:px-6 py-4 md:py-6 flex-1 overflow-y-auto">
                <div class="mb-4">
                  <p class="text-xs md:text-sm text-gray-600">
                    Initial Value:
                    <span class="font-semibold">
                      {format_number(@selected_investment.initial_value)}
                    </span>
                    (Created: {Date.to_string(DateTime.to_date(@selected_investment.inserted_at))})
                  </p>
                </div>

                <%= if Enum.empty?(@value_captures) do %>
                  <div class="text-center py-8 text-gray-500">
                    <p class="text-sm md:text-base">No value captures recorded yet.</p>
                    <p class="text-xs md:text-sm">
                      Use "Add Value" to create your first value capture.
                    </p>
                  </div>
                <% else %>
                  <!-- Desktop table view -->
                  <div class="hidden md:block overflow-hidden shadow ring-1 ring-black ring-opacity-5 rounded-lg max-h-96 overflow-y-auto">
                    <table class="min-w-full divide-y divide-gray-300">
                      <thead class="bg-gray-50">
                        <tr>
                          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Date
                          </th>
                          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Value
                          </th>
                          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Change
                          </th>
                          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                            Actions
                          </th>
                        </tr>
                      </thead>
                      <tbody class="bg-white divide-y divide-gray-200">
                        <%= for {vc, index} <- @value_captures |> Enum.with_index() do %>
                          <%= if @editing_value_capture_id == vc.id do %>
                            <tr class="bg-yellow-50">
                              <td colspan="4" class="px-6 py-4">
                                <.form
                                  for={@edit_value_capture_form}
                                  phx-submit="update_value_capture"
                                  class="flex items-center gap-4"
                                >
                                  <div>
                                    <label class="block text-xs font-medium text-gray-700">
                                      Date
                                    </label>
                                    <.input
                                      field={@edit_value_capture_form[:captured_at]}
                                      type="date"
                                      class="mt-1 text-sm"
                                      required
                                    />
                                  </div>
                                  <div>
                                    <label class="block text-xs font-medium text-gray-700">
                                      Value
                                    </label>
                                    <.input
                                      field={@edit_value_capture_form[:value]}
                                      type="number"
                                      step="0.01"
                                      class="mt-1 text-sm"
                                      required
                                    />
                                  </div>
                                  <div class="flex gap-2 mt-6">
                                    <button
                                      type="submit"
                                      class="bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded text-xs"
                                    >
                                      Save
                                    </button>
                                    <button
                                      type="button"
                                      phx-click="cancel_edit_value_capture"
                                      class="bg-gray-300 hover:bg-gray-400 text-gray-700 px-3 py-1 rounded text-xs"
                                    >
                                      Cancel
                                    </button>
                                  </div>
                                </.form>
                              </td>
                            </tr>
                          <% else %>
                            <tr>
                              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                {Date.to_string(vc.captured_at)}
                              </td>
                              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                {format_number(vc.value)}
                              </td>
                              <td class="px-6 py-4 whitespace-nowrap text-sm">
                                <%= if index == 0 do %>
                                  <% initial = Decimal.to_float(@selected_investment.initial_value) %>
                                  <% current = Decimal.to_float(vc.value) %>
                                  <% change =
                                    if initial == 0, do: 0, else: (current - initial) / initial * 100 %>
                                  <span class={[
                                    change > 0 && "text-green-600",
                                    change < 0 && "text-red-600",
                                    change == 0 && "text-gray-500"
                                  ]}>
                                    {if change >= 0, do: "+", else: ""}{:erlang.float_to_binary(
                                      change,
                                      [:compact, {:decimals, 2}]
                                    )}%
                                  </span>
                                <% else %>
                                  <% prev_value =
                                    Decimal.to_float(Enum.at(@value_captures, index - 1).value) %>
                                  <% current = Decimal.to_float(vc.value) %>
                                  <% change =
                                    if prev_value == 0,
                                      do: 0,
                                      else: (current - prev_value) / prev_value * 100 %>
                                  <span class={[
                                    change > 0 && "text-green-600",
                                    change < 0 && "text-red-600",
                                    change == 0 && "text-gray-500"
                                  ]}>
                                    {if change >= 0, do: "+", else: ""}{:erlang.float_to_binary(
                                      change,
                                      [:compact, {:decimals, 2}]
                                    )}%
                                  </span>
                                <% end %>
                              </td>
                              <td class="px-6 py-4 whitespace-nowrap text-sm">
                                <button
                                  type="button"
                                  phx-click="edit_value_capture"
                                  phx-value-id={vc.id}
                                  class="text-indigo-600 hover:text-indigo-900 text-xs"
                                >
                                  Edit
                                </button>
                              </td>
                            </tr>
                          <% end %>
                        <% end %>
                      </tbody>
                    </table>
                  </div>
                  
    <!-- Mobile card view -->
                  <div class="md:hidden space-y-3 max-h-96 overflow-y-auto">
                    <%= for {vc, index} <- @value_captures |> Enum.with_index() do %>
                      <%= if @editing_value_capture_id == vc.id do %>
                        <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
                          <.form
                            for={@edit_value_capture_form}
                            phx-submit="update_value_capture"
                            class="space-y-3"
                          >
                            <div>
                              <label class="block text-xs font-medium text-gray-700 mb-1">
                                Dates
                              </label>
                              <.input
                                field={@edit_value_capture_form[:captured_at]}
                                type="date"
                                class="w-full text-sm"
                                required
                              />
                            </div>
                            <div>
                              <label class="block text-xs font-medium text-gray-700 mb-1">
                                Value
                              </label>
                              <.input
                                field={@edit_value_capture_form[:value]}
                                type="number"
                                step="0.01"
                                class="w-full text-sm"
                                required
                              />
                            </div>
                            <div class="flex gap-2">
                              <button
                                type="submit"
                                class="flex-1 bg-green-600 hover:bg-green-700 text-white px-3 py-2 rounded text-sm"
                              >
                                Save
                              </button>
                              <button
                                type="button"
                                phx-click="cancel_edit_value_capture"
                                class="flex-1 bg-gray-300 hover:bg-gray-400 text-gray-700 px-3 py-2 rounded text-sm"
                              >
                                Cancel
                              </button>
                            </div>
                          </.form>
                        </div>
                      <% else %>
                        <div class="bg-white border border-gray-200 rounded-lg p-4 space-y-2">
                          <div class="flex justify-between items-start">
                            <div>
                              <p class="text-sm font-semibold text-gray-900">
                                {Date.to_string(vc.captured_at)}
                              </p>
                              <p class="text-lg font-bold text-gray-900">
                                {format_number(vc.value)}
                              </p>
                            </div>
                            <div class="text-right">
                              <%= if index == 0 do %>
                                <% initial = Decimal.to_float(@selected_investment.initial_value) %>
                                <% current = Decimal.to_float(vc.value) %>
                                <% change =
                                  if initial == 0, do: 0, else: (current - initial) / initial * 100 %>
                                <span class={[
                                  "px-2 py-1 rounded-full text-xs font-semibold",
                                  change > 0 && "bg-green-100 text-green-800",
                                  change < 0 && "bg-red-100 text-red-800",
                                  change == 0 && "bg-gray-100 text-gray-800"
                                ]}>
                                  {if change >= 0, do: "+", else: ""}{:erlang.float_to_binary(
                                    change,
                                    [:compact, {:decimals, 2}]
                                  )}%
                                </span>
                              <% else %>
                                <% prev_value =
                                  Decimal.to_float(Enum.at(@value_captures, index - 1).value) %>
                                <% current = Decimal.to_float(vc.value) %>
                                <% change =
                                  if prev_value == 0,
                                    do: 0,
                                    else: (current - prev_value) / prev_value * 100 %>
                                <span class={[
                                  "px-2 py-1 rounded-full text-xs font-semibold",
                                  change > 0 && "bg-green-100 text-green-800",
                                  change < 0 && "bg-red-100 text-red-800",
                                  change == 0 && "bg-gray-100 text-gray-800"
                                ]}>
                                  {if change >= 0, do: "+", else: ""}{:erlang.float_to_binary(
                                    change,
                                    [:compact, {:decimals, 2}]
                                  )}%
                                </span>
                              <% end %>
                            </div>
                          </div>
                          <div class="pt-2">
                            <button
                              type="button"
                              phx-click="edit_value_capture"
                              phx-value-id={vc.id}
                              class="w-full bg-indigo-100 hover:bg-indigo-200 text-indigo-800 px-3 py-2 rounded text-sm font-medium"
                            >
                              Edit
                            </button>
                          </div>
                        </div>
                      <% end %>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp prepare_comparison_chart_data(investments) do
    if Enum.empty?(investments) do
      %{
        labels: [],
        datasets: []
      }
    else
      # Create a simple chart with each investment as a line
      # For now, just use the first investment's data points for the x-axis
      first_inv = List.first(investments)

      # Create labels from the first investment's timeline
      # investment_date = DateTime.to_date(first_inv.inserted_at)
      capture_dates = Enum.map(first_inv.value_captures, & &1.captured_at)
      all_dates = Enum.sort(capture_dates, Date)
      labels = Enum.map(all_dates, &Date.to_string(&1))

      # Create datasets for each investment
      datasets =
        investments
        |> Enum.with_index()
        |> Enum.map(fn {inv, index} ->
          # investment_date = DateTime.to_date(inv.inserted_at)
          # Create data points: start with initial value, then add captures
          # data_points = [{investment_date, Decimal.to_float(inv.initial_value)}]

          capture_points =
            Enum.map(inv.value_captures, fn vc ->
              {vc.captured_at, Decimal.to_float(vc.value)}
            end)

          # all_points = (data_points ++ capture_points) |> Enum.sort_by(&elem(&1, 0), Date)
          all_points = Enum.sort_by(capture_points, &elem(&1, 0), Date)

          data = Enum.map(all_points, &elem(&1, 1))

          # Generate a unique color for each investment
          colors = [
            # green
            "rgb(34, 197, 94)",
            # blue
            "rgb(59, 130, 246)",
            # red
            "rgb(239, 68, 68)",
            # yellow
            "rgb(245, 158, 11)",
            # purple
            "rgb(168, 85, 247)",
            # pink
            "rgb(236, 72, 153)",
            # sky
            "rgb(14, 165, 233)"
          ]

          color = Enum.at(colors, rem(index, length(colors)))

          %{
            label: inv.name,
            data: data,
            borderColor: color,
            backgroundColor:
              String.replace(color, "rgb(", "rgba(") |> String.replace(")", ", 0.1)"),
            fill: false,
            tension: 0.2,
            pointRadius: 4,
            pointHoverRadius: 7
          }
        end)

      %{
        labels: labels,
        datasets: datasets
      }
    end
  end

  defp calculate_changes_by_date(investments) do
    # Collect all value captures with their dates across all investments
    all_captures =
      investments
      |> Enum.flat_map(fn inv ->
        inv.value_captures
        |> Enum.sort_by(& &1.captured_at, Date)
        |> Enum.with_index()
        |> Enum.map(fn {vc, index} ->
          # Calculate the change for this capture
          previous_value =
            if index == 0 do
              Decimal.to_float(inv.initial_value)
            else
              sorted = Enum.sort_by(inv.value_captures, & &1.captured_at, Date)
              Decimal.to_float(Enum.at(sorted, index - 1).value)
            end

          current_value = Decimal.to_float(vc.value)
          change = current_value - previous_value

          {vc.captured_at, change}
        end)
      end)

    # Group by date and sum the changes
    all_captures
    |> Enum.group_by(fn {date, _change} -> date end, fn {_date, change} -> change end)
    |> Enum.map(fn {date, changes} -> {date, Enum.sum(changes)} end)
    |> Enum.sort_by(fn {date, _change} -> date end, {:desc, Date})
  end
end

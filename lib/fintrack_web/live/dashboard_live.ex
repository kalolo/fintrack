defmodule FinTrackWeb.DashboardLive do
  use FinTrackWeb, :live_view

  alias FinTrack.Billing

  require Logger

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user}>
      <.header>
        📊 Financial Dashboard
        <:subtitle>Overview of your income and expenses</:subtitle>
      </.header>
      
    <!-- Date Range Picker -->
      <div class="mb-6 p-4 bg-white rounded-lg shadow">
        <form
          phx-submit="update_date_range"
          class="flex flex-col md:flex-row md:items-center md:space-x-4 space-y-2 md:space-y-0"
        >
          <div class="flex items-center space-x-2">
            <label class="text-sm font-medium text-gray-700">Date Range:</label>
            <select
              name="range_preset"
              phx-change="preset_changed"
              class="border border-gray-300 rounded-md px-3 py-2 text-sm"
            >
              <option value="currentmonth" selected={@selected_range == "currentmonth"}>
                Current Month
              </option>
              <option value="previousmonth" selected={@selected_range == "previousmonth"}>
                Previous Month
              </option>
              <option value="30" selected={@selected_range == "30"}>Last 30 Days</option>
              <option value="90" selected={@selected_range == "90"}>Last 90 Days</option>
              <option value="180" selected={@selected_range == "180"}>Last 6 Months</option>
              <option value="365" selected={@selected_range == "365"}>Last Year</option>
              <option value="custom" selected={@selected_range == "custom"}>Custom Range</option>
            </select>
          </div>

          <%= if @selected_range == "custom" do %>
            <div class="flex items-center space-x-2 mt-2 md:mt-0">
              <input
                type="date"
                name="date_from"
                value={@date_from}
                class="border border-gray-300 rounded-md px-3 py-2 text-sm"
                aria-label="From date"
              />
              <span class="text-gray-500">to</span>
              <input
                type="date"
                name="date_to"
                value={@date_to}
                class="border border-gray-300 rounded-md px-3 py-2 text-sm"
                aria-label="To date"
              />
              <.button
                type="submit"
                class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded text-sm"
              >
                Apply
              </.button>
            </div>
          <% end %>
        </form>
      </div>
      
    <!-- Key Metrics Cards -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-6 mb-6">
        <div class="bg-green-50 p-6 rounded-lg shadow">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <i class="fas fa-arrow-up text-green-500 text-2xl"></i>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-green-600">Total Income</p>
              <p class="text-2xl font-bold text-green-900">
                {format_currency(@dashboard_data.metrics.total_income)}
              </p>
            </div>
          </div>
        </div>

        <div class="bg-red-50 p-6 rounded-lg shadow">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <i class="fas fa-arrow-down text-red-500 text-2xl"></i>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-red-600">Total Expenses</p>
              <p class="text-2xl font-bold text-red-900">
                {format_currency(@dashboard_data.metrics.total_expenses)}
              </p>
            </div>
          </div>
        </div>

        <div class={[
          "p-6 rounded-lg shadow",
          @dashboard_data.metrics.net_profit >= 0 && "bg-blue-50",
          @dashboard_data.metrics.net_profit < 0 && "bg-yellow-50"
        ]}>
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <i class={[
                "text-2xl",
                @dashboard_data.metrics.net_profit >= 0 && "fas fa-chart-line text-blue-500",
                @dashboard_data.metrics.net_profit < 0 &&
                  "fas fa-exclamation-triangle text-yellow-500"
              ]}>
              </i>
            </div>
            <div class="ml-4">
              <p class={[
                "text-sm font-medium",
                @dashboard_data.metrics.net_profit >= 0 && "text-blue-600",
                @dashboard_data.metrics.net_profit < 0 && "text-yellow-600"
              ]}>
                Net Profit
              </p>
              <p class={[
                "text-2xl font-bold",
                @dashboard_data.metrics.net_profit >= 0 && "text-blue-900",
                @dashboard_data.metrics.net_profit < 0 && "text-yellow-900"
              ]}>
                {format_currency(@dashboard_data.metrics.net_profit)}
              </p>
            </div>
          </div>
        </div>

        <div class="bg-purple-50 p-6 rounded-lg shadow">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <i class="fas fa-percentage text-purple-500 text-2xl"></i>
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-purple-600">Profit Margin</p>
              <p class="text-2xl font-bold text-purple-900">
                {format_percentage(@dashboard_data.metrics.profit_margin)}%
              </p>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Payment Method Totals -->
      <%= if not Enum.empty?(@dashboard_data.payment_method_breakdown) do %>
        <div class="mb-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Payment Method Breakdown</h3>
          <div class="grid grid-cols-1 md:grid-cols-5 gap-4">
            <%= for {method_data, index} <- Enum.with_index(@dashboard_data.payment_method_breakdown) do %>
              <% color_classes = get_payment_method_colors(index) %>
              <div class={[
                "p-4 rounded-lg shadow-sm border-l-4",
                color_classes.bg,
                color_classes.border
              ]}>
                <div class="space-y-1">
                  <p class={["text-xs font-medium uppercase tracking-wider", color_classes.text]}>
                    {method_data.display_name}
                  </p>
                  <p class={["text-lg font-bold", color_classes.text_dark]}>
                    {format_currency(method_data.total_amount)}
                  </p>
                  <div class="space-y-0.5">
                    <p class="text-xs text-green-600">
                      Income: {format_currency(method_data.income_amount)}
                    </p>
                    <p class="text-xs text-red-600">
                      Expenses: {format_currency(method_data.expense_amount)}
                    </p>
                    <p class="text-xs text-gray-500">
                      {method_data.transaction_count} transactions
                    </p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
      
    <!-- Charts Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <!-- Income vs Expenses Line Chart -->
        <div class="bg-white p-6 rounded-lg shadow">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Income vs Expenses Over Time</h3>
          <div class="relative h-80 w-full">
            <canvas
              id="incomeExpenseChart"
              phx-hook="IncomeExpenseChart"
              data-chart-data={Jason.encode!(@chart_data.income_expense_chart)}
              class="w-full h-full"
            >
            </canvas>
          </div>
        </div>
        
    <!-- Monthly Comparison Bar Chart -->
        <div class="bg-white p-6 rounded-lg shadow">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Monthly Comparison</h3>
          <div class="relative h-80 w-full">
            <canvas
              id="monthlyChart"
              phx-hook="MonthlyChart"
              data-chart-data={Jason.encode!(@chart_data.monthly_chart)}
              class="w-full h-full"
            >
            </canvas>
          </div>
        </div>
        
    <!-- Income/Expense Ratio Pie Chart -->
        <div class="bg-white p-6 rounded-lg shadow">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Income vs Expense Ratio</h3>
          <div class="relative h-80 w-full">
            <canvas
              id="ratioChart"
              phx-hook="RatioChart"
              data-chart-data={Jason.encode!(@chart_data.ratio_chart)}
              class="w-full h-full"
            >
            </canvas>
          </div>
        </div>
        
    <!-- Payment Method Breakdown Chart -->
        <div class="bg-white p-6 rounded-lg shadow">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Transactions by Payment Method</h3>
          <div class="relative h-80 w-full">
            <canvas
              id="paymentMethodChart"
              phx-hook="PaymentMethodChart"
              data-chart-data={Jason.encode!(@chart_data.payment_method_chart)}
              class="w-full h-full"
            >
            </canvas>
          </div>
        </div>
        
    <!-- Cumulative Cash Flow Area Chart -->
        <div class="bg-white p-6 rounded-lg shadow">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Cumulative Cash Flow</h3>
          <div class="relative h-80 w-full">
            <canvas
              id="cumulativeChart"
              phx-hook="CumulativeChart"
              data-chart-data={Jason.encode!(@chart_data.cumulative_chart)}
              class="w-full h-full"
            >
            </canvas>
          </div>
        </div>
        
    <!-- Net Profit Per Month Line Chart -->
        <div class="bg-white p-6 rounded-lg shadow">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Net Profit Per Month</h3>
          <div class="relative h-80 w-full">
            <canvas
              id="netProfitChart"
              phx-hook="NetProfitChart"
              data-chart-data={Jason.encode!(@chart_data.net_profit_chart)}
              class="w-full h-full"
            >
            </canvas>
          </div>
        </div>
      </div>
      
    <!-- Transaction Summary Table -->
      <div class="bg-white rounded-lg shadow mb-6">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Recent Activity Summary</h3>
        </div>
        <div class="p-6">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-center">
            <div>
              <p class="text-3xl font-bold text-gray-900">
                {@dashboard_data.metrics.transaction_count}
              </p>
              <p class="text-sm text-gray-500">Total Transactions</p>
            </div>
            <div>
              <p class="text-3xl font-bold text-green-600">
                {length(Enum.filter(@dashboard_data.daily_data, &(&1.income > 0)))}
              </p>
              <p class="text-sm text-gray-500">Days with Income</p>
            </div>
            <div>
              <p class="text-3xl font-bold text-red-600">
                {length(Enum.filter(@dashboard_data.daily_data, &(&1.expenses > 0)))}
              </p>
              <p class="text-sm text-gray-500">Days with Expenses</p>
            </div>
          </div>
        </div>
      </div>
      <!-- All-Time Monthly Summary Table -->
      <div class="bg-white rounded-lg shadow">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">All-Time Monthly Performance</h3>
          <p class="text-sm text-gray-500 mt-1">
            Historical overview of income, expenses, and profitability by month
          </p>
        </div>
        <div class="overflow-x-auto">
          <%= if Enum.empty?(@monthly_summary) do %>
            <div class="p-6 text-center text-gray-500">
              No transaction data available yet
            </div>
          <% else %>
            <table class="min-w-full divide-y divide-gray-200">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Month
                  </th>
                  <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Total Income
                  </th>
                  <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Total Expenses
                  </th>
                  <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Net Profit
                  </th>
                  <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Margin %
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for month_data <- Enum.reverse(@monthly_summary) do %>
                  <tr class="hover:bg-gray-50 transition-colors">
                    <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                      {Calendar.strftime(month_data.month, "%B %Y")}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-right text-green-600 font-semibold">
                      {format_currency(month_data.income)}
                    </td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-right text-red-600 font-semibold">
                      {format_currency(month_data.expenses)}
                    </td>
                    <td class={[
                      "px-6 py-4 whitespace-nowrap text-sm text-right font-bold",
                      month_data.net >= 0 && "text-blue-600",
                      month_data.net < 0 && "text-yellow-600"
                    ]}>
                      {format_currency(month_data.net)}
                    </td>
                    <td class={[
                      "px-6 py-4 whitespace-nowrap text-sm text-right font-semibold",
                      month_data.margin >= 0 && "text-purple-600",
                      month_data.margin < 0 && "text-yellow-600"
                    ]}>
                      {format_percentage(month_data.margin)}%
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # Default to last 30 days
    # date_to = Date.utc_today()
    # date_from = Date.add(date_to, -30)

    # Default to current month
    date_to = Date.utc_today()
    date_from = Date.beginning_of_month(date_to)

    # Get all-time monthly summary (independent of date range)
    monthly_summary = Billing.get_all_time_monthly_summary(socket.assigns.current_user.id)

    socket =
      socket
      |> assign(:selected_range, "currentmonth")
      |> assign(:date_from, Date.to_string(date_from))
      |> assign(:date_to, Date.to_string(date_to))
      |> assign(:monthly_summary, monthly_summary)
      |> load_dashboard_data(date_from, date_to)

    {:ok, socket}
  end

  @impl true
  def handle_event("preset_changed", %{"range_preset" => range}, socket) do
    socket =
      socket
      |> assign(:selected_range, range)

    socket =
      case range do
        "currentmonth" ->
          date_to = Date.utc_today()
          date_from = Date.beginning_of_month(date_to)

          Logger.info("Current month from #{date_from} to #{date_to}")

          socket
          |> assign(:date_from, Date.to_string(date_from))
          |> assign(:date_to, Date.to_string(date_to))
          |> load_dashboard_data(date_from, date_to)

        "previousmonth" ->
          date_to = Date.beginning_of_month(Date.utc_today()) |> Date.add(-1)
          date_from = Date.beginning_of_month(date_to)

          Logger.info("Previous month from #{date_from} to #{date_to}")

          socket
          |> assign(:date_from, Date.to_string(date_from))
          |> assign(:date_to, Date.to_string(date_to))
          |> load_dashboard_data(date_from, date_to)

        "custom" ->
          socket

        _ ->
          {date_from, date_to} = get_date_range_for_preset(range)

          socket
          |> assign(:date_from, Date.to_string(date_from))
          |> assign(:date_to, Date.to_string(date_to))
          |> load_dashboard_data(date_from, date_to)
      end

    # if range != "custom" do
    #   {date_from, date_to} = get_date_range_for_preset(range)

    #   socket
    #   |> assign(:date_from, Date.to_string(date_from))
    #   |> assign(:date_to, Date.to_string(date_to))
    #   |> load_dashboard_data(date_from, date_to)
    # else
    #   socket
    # end

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_date_range", params, socket) do
    case params do
      %{"date_from" => from_str, "date_to" => to_str} ->
        with {:ok, date_from} <- Date.from_iso8601(from_str),
             {:ok, date_to} <- Date.from_iso8601(to_str),
             :ok <- validate_date_range(date_from, date_to) do
          socket =
            socket
            |> assign(:selected_range, "custom")
            |> assign(:date_from, from_str)
            |> assign(:date_to, to_str)
            |> load_dashboard_data(date_from, date_to)

          {:noreply, socket}
        else
          {:error, message} ->
            {:noreply, put_flash(socket, :error, message)}

          _ ->
            {:noreply, put_flash(socket, :error, "Invalid date range")}
        end

      _ ->
        {:noreply, put_flash(socket, :error, "Missing date range parameters")}
    end
  end

  defp get_date_range_for_preset(range) do
    date_to = Date.utc_today()
    days = String.to_integer(range)
    date_from = Date.add(date_to, -days)
    {date_from, date_to}
  end

  defp prepare_chart_data(dashboard_data) do
    %{
      income_expense_chart: prepare_income_expense_chart_data(dashboard_data.daily_data),
      monthly_chart: prepare_monthly_chart_data(dashboard_data.monthly_data),
      net_profit_chart: prepare_net_profit_chart_data(dashboard_data.monthly_data),
      ratio_chart: prepare_ratio_chart_data(dashboard_data.income_expense_ratio),
      cumulative_chart: prepare_cumulative_chart_data(dashboard_data.cumulative_flow),
      payment_method_chart:
        prepare_payment_method_chart_data(dashboard_data.payment_method_breakdown)
    }
  end

  defp prepare_income_expense_chart_data(daily_data) do
    labels = Enum.map(daily_data, &Calendar.strftime(&1.date, "%m/%d"))
    income_data = Enum.map(daily_data, & &1.income)
    expense_data = Enum.map(daily_data, & &1.expenses)

    %{
      labels: labels,
      datasets: [
        %{
          label: "Income",
          data: income_data,
          borderColor: "rgb(34, 197, 94)",
          backgroundColor: "rgba(34, 197, 94, 0.1)",
          tension: 0.1
        },
        %{
          label: "Expenses",
          data: expense_data,
          borderColor: "rgb(239, 68, 68)",
          backgroundColor: "rgba(239, 68, 68, 0.1)",
          tension: 0.1
        }
      ]
    }
  end

  defp prepare_monthly_chart_data(monthly_data) do
    labels = Enum.map(monthly_data, &Calendar.strftime(&1.month, "%b %Y"))
    income_data = Enum.map(monthly_data, & &1.income)
    expense_data = Enum.map(monthly_data, & &1.expenses)

    %{
      labels: labels,
      datasets: [
        %{
          label: "Income",
          data: income_data,
          backgroundColor: "rgba(34, 197, 94, 0.8)"
        },
        %{
          label: "Expenses",
          data: expense_data,
          backgroundColor: "rgba(239, 68, 68, 0.8)"
        }
      ]
    }
  end

  defp prepare_ratio_chart_data(ratio_data) do
    %{
      labels: ["Income", "Expenses"],
      datasets: [
        %{
          data: [ratio_data.income_amount, ratio_data.expense_amount],
          backgroundColor: [
            "rgba(34, 197, 94, 0.8)",
            "rgba(239, 68, 68, 0.8)"
          ],
          borderColor: [
            "rgb(34, 197, 94)",
            "rgb(239, 68, 68)"
          ],
          borderWidth: 1
        }
      ]
    }
  end

  defp prepare_net_profit_chart_data(monthly_data) do
    labels = Enum.map(monthly_data, &Calendar.strftime(&1.month, "%b %Y"))
    net_profit_data = Enum.map(monthly_data, & &1.net)

    %{
      labels: labels,
      datasets: [
        %{
          label: "Net Profit",
          data: net_profit_data,
          borderColor: "rgb(251, 191, 36)",
          backgroundColor: "rgba(251, 191, 36, 0.1)",
          fill: true,
          tension: 0.25,
          pointRadius: 4,
          pointHoverRadius: 7
        }
      ]
    }
  end

  defp prepare_cumulative_chart_data(cumulative_data) do
    labels = Enum.map(cumulative_data, &Calendar.strftime(&1.date, "%m/%d"))
    amounts = Enum.map(cumulative_data, & &1.amount)

    %{
      labels: labels,
      datasets: [
        %{
          label: "Cumulative Cash Flow",
          data: amounts,
          borderColor: "rgb(59, 130, 246)",
          backgroundColor: "rgba(59, 130, 246, 0.1)",
          fill: true,
          tension: 0.4
        }
      ]
    }
  end

  defp prepare_payment_method_chart_data(payment_method_data) do
    # Handle case where there's no data
    if Enum.empty?(payment_method_data) do
      %{
        labels: ["No Data"],
        datasets: [
          %{
            label: "Total Amount",
            data: [0],
            backgroundColor: ["rgba(156, 163, 175, 0.8)"],
            borderColor: ["rgb(156, 163, 175)"],
            borderWidth: 1
          }
        ]
      }
    else
      labels = Enum.map(payment_method_data, & &1.display_name)
      amounts = Enum.map(payment_method_data, & &1.total_amount)

      # Generate distinct colors for each payment method
      colors = [
        # Green for first method
        "rgba(34, 197, 94, 0.8)",
        # Blue
        "rgba(59, 130, 246, 0.8)",
        # Red
        "rgba(239, 68, 68, 0.8)",
        # Yellow
        "rgba(251, 191, 36, 0.8)",
        # Purple
        "rgba(168, 85, 247, 0.8)",
        # Pink
        "rgba(236, 72, 153, 0.8)",
        # Teal
        "rgba(20, 184, 166, 0.8)"
      ]

      border_colors = [
        "rgb(34, 197, 94)",
        "rgb(59, 130, 246)",
        "rgb(239, 68, 68)",
        "rgb(251, 191, 36)",
        "rgb(168, 85, 247)",
        "rgb(236, 72, 153)",
        "rgb(20, 184, 166)"
      ]

      %{
        labels: labels,
        datasets: [
          %{
            label: "Total Amount",
            data: amounts,
            backgroundColor: Enum.take(colors, length(labels)),
            borderColor: Enum.take(border_colors, length(labels)),
            borderWidth: 1
          }
        ]
      }
    end
  end

  defp validate_date_range(date_from, date_to) do
    cond do
      Date.compare(date_from, date_to) == :gt ->
        {:error, "Start date cannot be after end date"}

      Date.diff(date_to, date_from) > 730 ->
        {:error, "Date range cannot exceed 2 years"}

      Date.compare(date_from, Date.utc_today()) == :gt ->
        {:error, "Start date cannot be in the future"}

      true ->
        :ok
    end
  end

  defp load_dashboard_data(socket, date_from, date_to) do
    # Convert dates to NaiveDateTime for database query
    datetime_from = NaiveDateTime.new!(date_from, ~T[00:00:00])
    datetime_to = NaiveDateTime.new!(date_to, ~T[23:59:59])

    try do
      dashboard_data =
        Billing.get_dashboard_data(socket.assigns.current_user.id, datetime_from, datetime_to)

      chart_data = prepare_chart_data(dashboard_data)

      socket
      |> assign(:dashboard_data, dashboard_data)
      |> assign(:chart_data, chart_data)
      |> assign(:page_title, "Dashboard")
    rescue
      e ->
        # Log the error for debugging
        require Logger
        Logger.error("Dashboard data loading failed: #{inspect(e)}")

        # Return socket with error flash
        put_flash(
          socket,
          :error,
          "Failed to load dashboard data. Please try a different date range."
        )
    end
  end

  defp format_percentage(value) when is_integer(value) do
    value
    |> Kernel./(1.0)
    |> Float.round(1)
    |> :erlang.float_to_binary([:compact, {:decimals, 1}])
  end

  defp format_percentage(value) when is_float(value) do
    value
    |> Float.round(1)
    |> :erlang.float_to_binary([:compact, {:decimals, 1}])
  end

  defp format_percentage(_), do: "0.0"

  defp get_payment_method_colors(index) do
    color_schemes = [
      %{
        bg: "bg-green-50",
        border: "border-green-400",
        text: "text-green-600",
        text_dark: "text-green-900"
      },
      %{
        bg: "bg-blue-50",
        border: "border-blue-400",
        text: "text-blue-600",
        text_dark: "text-blue-900"
      },
      %{
        bg: "bg-red-50",
        border: "border-red-400",
        text: "text-red-600",
        text_dark: "text-red-900"
      },
      %{
        bg: "bg-yellow-50",
        border: "border-yellow-400",
        text: "text-yellow-600",
        text_dark: "text-yellow-900"
      },
      %{
        bg: "bg-purple-50",
        border: "border-purple-400",
        text: "text-purple-600",
        text_dark: "text-purple-900"
      },
      %{
        bg: "bg-pink-50",
        border: "border-pink-400",
        text: "text-pink-600",
        text_dark: "text-pink-900"
      },
      %{
        bg: "bg-teal-50",
        border: "border-teal-400",
        text: "text-teal-600",
        text_dark: "text-teal-900"
      }
    ]

    Enum.at(color_schemes, rem(index, length(color_schemes)))
  end
end

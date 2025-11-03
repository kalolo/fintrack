defmodule InvoicesWeb.Helpers.FormatHelper do
  @moduledoc """
  Helper functions for formatting data in templates.
  """

  @doc """
  Formats a decimal amount as currency with proper formatting.

  Examples:

    iex> format_currency(Decimal.new("1234.56"))
    "$1,234.56"
    
    iex> format_currency(Decimal.new("73500"))
    "$73,500.00"
  """
  def format_currency(%Decimal{} = amount) do
    # Convert Decimal to float using Decimal.to_float for proper handling
    amount
    |> Decimal.to_float()
    |> format_currency()
  end

  def format_currency(amount) when is_binary(amount) do
    # Handle both integer strings ("70") and decimal strings ("70.5")
    case Float.parse(amount) do
      {float_amount, _} ->
        format_currency(float_amount)

      :error ->
        # If Float.parse fails, try converting via Decimal for robust parsing
        try do
          amount
          |> Decimal.new()
          |> Decimal.to_float()
          |> format_currency()
        rescue
          # Fallback for invalid inputs
          _ -> "$0.00"
        end
    end
  end

  def format_currency(amount) when is_float(amount) or is_integer(amount) do
    amount
    |> ensure_float()
    |> :erlang.float_to_binary(decimals: 2)
    |> add_thousand_separators()
    |> then(&"$#{&1}")
  end

  defp ensure_float(amount) when is_float(amount), do: amount
  defp ensure_float(amount) when is_integer(amount), do: amount * 1.0

  @doc """
  Formats a decimal amount with commas but without the dollar sign.

  Examples:

    iex> format_number(Decimal.new("1234.56"))
    "1,234.56"

    iex> format_number(Decimal.new("73500"))
    "73,500.00"
  """
  def format_number(amount) do
    format_currency(amount) |> String.replace_prefix("$", "")
  end

  defp add_thousand_separators(amount_string) do
    [integer_part, decimal_part] = String.split(amount_string, ".")

    formatted_integer =
      integer_part
      |> String.reverse()
      |> String.graphemes()
      |> Enum.chunk_every(3)
      |> Enum.map(&Enum.join/1)
      |> Enum.join(",")
      |> String.reverse()

    "#{formatted_integer}.#{decimal_part}"
  end
end

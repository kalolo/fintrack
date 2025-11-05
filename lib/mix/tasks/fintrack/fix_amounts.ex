defmodule Mix.Tasks.FinTrack.FixAmounts do
  use Mix.Task

  @shortdoc "Fix amounts for historical invoices by re-extracting from Excel files"

  @moduledoc """
  Fix amounts for existing historical invoices by re-reading Excel files.

  Usage:
      mix fintrack.fix_amounts

  This task will:
  1. Find all imported historical invoices (with description "Imported historical invoice")
  2. Re-extract the correct amount from their corresponding Excel files
  3. Update the database with the correct amounts
  """

  import Ecto.Query
  alias FinTrack.Repo
  alias FinTrack.Billing.Invoice

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    IO.puts("Fixing amounts for historical invoices...")

    # Get all historical invoices that need fixing
    historical_invoices = get_historical_invoices()

    IO.puts("Found #{length(historical_invoices)} historical invoices to fix...")

    {updated_count, failed_count} =
      Enum.reduce(historical_invoices, {0, 0}, fn invoice, {updated, failed} ->
        case fix_invoice_amount(invoice) do
          {:ok, new_amount} ->
            IO.puts(
              "✓ Updated Invoice #{invoice.invoice_number}: #{invoice.amount} -> #{new_amount}"
            )

            {updated + 1, failed}

          {:skip, reason} ->
            IO.puts("- Skipped Invoice #{invoice.invoice_number}: #{reason}")
            {updated, failed}

          {:error, reason} ->
            IO.puts("✗ Failed Invoice #{invoice.invoice_number}: #{reason}")
            {updated, failed + 1}
        end
      end)

    IO.puts("\\nAmount fixing completed!")
    IO.puts("Updated: #{updated_count} invoices")
    IO.puts("Failed: #{failed_count} invoices")
  end

  defp get_historical_invoices do
    Repo.all(
      from(i in Invoice,
        where: i.description == "Imported historical invoice",
        order_by: i.invoice_number
      )
    )
  end

  defp fix_invoice_amount(invoice) do
    # Find the corresponding Excel file
    case find_excel_file(invoice.invoice_number, invoice.date) do
      {:ok, file_path} ->
        case extract_amount_from_excel(file_path) do
          {:ok, new_amount} ->
            # Only update if the amount is different
            if Decimal.equal?(invoice.amount, new_amount) do
              {:skip, "amount already correct"}
            else
              update_invoice_amount(invoice, new_amount)
            end

          {:error, reason} ->
            {:error, "could not extract amount: #{reason}"}
        end

      {:error, reason} ->
        {:error, "could not find Excel file: #{reason}"}
    end
  end

  defp find_excel_file(invoice_number, date) do
    past_invoices_dir = Path.join([File.cwd!(), "past_invoices"])

    # Try different filename patterns that might exist
    patterns = [
      # Original format: Invoice 45 - 02_12_2022.xlsx  
      "Invoice #{invoice_number} - #{String.pad_leading(to_string(date.month), 2, "0")}_#{String.pad_leading(to_string(date.day), 2, "0")}_#{date.year}.xlsx",
      "Invoice #{invoice_number} - #{String.pad_leading(to_string(date.day), 2, "0")}_#{String.pad_leading(to_string(date.month), 2, "0")}_#{date.year}.xlsx",
      # ISO format: Invoice 45 - 2022-12-02.xlsx
      "Invoice #{invoice_number} - #{Date.to_iso8601(date)}.xlsx",
      # Any format with this invoice number
      "Invoice #{invoice_number} - *.xlsx"
    ]

    # Search for files matching any of these patterns
    found_files =
      patterns
      |> Enum.flat_map(fn pattern ->
        Path.wildcard(Path.join([past_invoices_dir, "**", pattern]))
      end)
      |> Enum.uniq()

    case found_files do
      [file_path | _] ->
        {:ok, file_path}

      [] ->
        {:error, "no file found for invoice #{invoice_number}"}
    end
  end

  defp extract_amount_from_excel(file_path) do
    try do
      {:ok, pid} = Xlsxir.extract(file_path, 0)
      cells = Xlsxir.get_list(pid)
      amount = find_amount_in_cells(cells)
      Xlsxir.close(pid)
      {:ok, amount}
    rescue
      e ->
        {:error, "Excel parsing failed: #{inspect(e)}"}
    end
  end

  defp find_amount_in_cells(cells) do
    # Use the improved logic from the import task
    flat_cells = List.flatten(cells)

    # Find potential amounts - prefer floats, exclude large integers
    potential_amounts =
      flat_cells
      |> Enum.filter(&is_number/1)
      |> Enum.filter(&(&1 > 0))
      |> Enum.filter(&(&1 < 1_000_000))
      # Reject large integers (likely invoice numbers)
      |> Enum.reject(&(is_integer(&1) && &1 > 99999))
      # Prefer floats over integers for amounts
      |> Enum.reject(&is_integer/1)

    case potential_amounts do
      [] ->
        # If no floats found, try again with integers but with stricter filtering
        fallback_amounts =
          flat_cells
          |> Enum.filter(&is_number/1)
          |> Enum.filter(&(&1 > 0))
          # Much stricter limit for integers
          |> Enum.filter(&(&1 < 100_000))
          # Most invoice amounts are under $50k
          |> Enum.reject(&(&1 > 50000))

        case fallback_amounts do
          [] ->
            Decimal.new("0.00")

          amounts ->
            amount_frequencies = Enum.frequencies(amounts)
            duplicated = Enum.filter(amount_frequencies, fn {_amount, count} -> count > 1 end)

            final_amount =
              case duplicated do
                [{amount, _count} | _] -> amount
                [] -> Enum.max(amounts)
              end

            Decimal.new(to_string(final_amount))
        end

      amounts ->
        # For invoices, the amount usually appears twice (line item + total)
        amount_frequencies = Enum.frequencies(amounts)

        # Prefer amounts that appear exactly twice (standard invoice format)
        duplicated_twice = Enum.filter(amount_frequencies, fn {_amount, count} -> count == 2 end)

        final_amount =
          case duplicated_twice do
            [{amount, _count} | _] ->
              # Use the first amount that appears exactly twice
              amount

            [] ->
              # Fallback: look for any duplicated amounts
              duplicated = Enum.filter(amount_frequencies, fn {_amount, count} -> count > 1 end)

              case duplicated do
                [{amount, _count} | _] -> amount
                # Last resort: largest amount
                [] -> Enum.max(amounts)
              end
          end

        Decimal.new(to_string(final_amount))
    end
  end

  defp update_invoice_amount(invoice, new_amount) do
    case Repo.update(Ecto.Changeset.change(invoice, amount: new_amount)) do
      {:ok, _updated_invoice} ->
        {:ok, new_amount}

      {:error, changeset} ->
        {:error, "database update failed: #{inspect(changeset.errors)}"}
    end
  end
end

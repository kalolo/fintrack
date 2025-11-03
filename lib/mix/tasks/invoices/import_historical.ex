defmodule Mix.Tasks.Invoices.ImportHistorical do
  use Mix.Task

  @shortdoc "Import historical invoices from past_invoices directory"

  @moduledoc """
  Import historical invoices from Excel files in the past_invoices directory.

  Usage:
      mix invoices.import_historical

  This task will:
  1. Scan all Excel files in the past_invoices directory
  2. Extract invoice number, date, and amount from file names and content
  3. Create corresponding records in the invoices table
  4. Assign them to the first user in the system
  """

  alias Invoices.Repo
  alias Invoices.Billing.Invoice
  alias Invoices.Accounts

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")

    IO.puts("Starting historical invoice import...")

    # Get the first user to assign invoices to
    case get_first_user() do
      nil ->
        IO.puts("Error: No users found in the system. Please create a user first.")
        System.halt(1)

      user ->
        IO.puts("Assigning invoices to user: #{user.email}")
        import_invoices(user.id)
    end
  end

  defp get_first_user do
    Accounts.list_users() |> List.first()
  end

  defp import_invoices(user_id) do
    past_invoices_dir = Path.join([File.cwd!(), "past_invoices"])

    if not File.exists?(past_invoices_dir) do
      IO.puts("Error: past_invoices directory not found")
      System.halt(1)
    end

    # Get all Excel files recursively
    excel_files = find_excel_files(past_invoices_dir)

    IO.puts("Found #{length(excel_files)} Excel files to process...")

    {imported_count, skipped_count} =
      Enum.reduce(excel_files, {0, 0}, fn file_path, {imported, skipped} ->
        case import_single_invoice(file_path, user_id) do
          {:ok, invoice} ->
            IO.puts("✓ Imported: #{invoice.invoice_number}")
            {imported + 1, skipped}

          {:skip, reason} ->
            IO.puts("- Skipped #{Path.basename(file_path)}: #{reason}")
            {imported, skipped + 1}

          {:error, reason} ->
            IO.puts("✗ Error importing #{Path.basename(file_path)}: #{reason}")
            {imported, skipped + 1}
        end
      end)

    IO.puts("\\nImport completed!")
    IO.puts("Imported: #{imported_count} invoices")
    IO.puts("Skipped: #{skipped_count} files")
  end

  defp find_excel_files(dir) do
    Path.wildcard(Path.join([dir, "**", "*.xlsx"]))
    |> Enum.sort()
  end

  defp import_single_invoice(file_path, user_id) do
    _file_name = Path.basename(file_path, ".xlsx")

    case extract_invoice_data_from_excel(file_path) do
      {:ok, invoice_number, date, amount} ->
        # Check if invoice already exists
        existing = Repo.get_by(Invoice, invoice_number: invoice_number)

        if existing do
          {:skip, "already exists"}
        else
          create_invoice_record(invoice_number, date, amount, user_id)
        end

      {:error, reason} ->
        {:error, "data extraction failed: #{reason}"}
    end
  end

  defp find_invoice_number_in_cells(cells) do
    # Look for the "INVOICE NO." field and get the adjacent cell value
    flat_cells_with_positions =
      cells
      |> Enum.with_index()
      |> Enum.flat_map(fn {row, row_idx} ->
        row
        |> Enum.with_index()
        |> Enum.map(fn {cell, col_idx} -> {cell, row_idx, col_idx} end)
      end)

    # Find "INVOICE NO." cell
    case Enum.find(flat_cells_with_positions, fn {cell, _, _} ->
           is_binary(cell) && String.contains?(String.upcase(cell), "INVOICE NO")
         end) do
      {_, invoice_row, invoice_col} ->
        # Look for the invoice number in adjacent cells (right or below)
        adjacent_positions = [
          # Right
          {invoice_row, invoice_col + 1},
          # Below
          {invoice_row + 1, invoice_col}
        ]

        Enum.find_value(adjacent_positions, fn {row, col} ->
          case Enum.find(flat_cells_with_positions, fn {_, r, c} -> r == row && c == col end) do
            {cell_value, _, _} when is_number(cell_value) ->
              # Convert to string and remove .0 if it's a whole number
              invoice_num_str =
                if cell_value == trunc(cell_value) do
                  to_string(trunc(cell_value))
                else
                  to_string(cell_value)
                end

              # Extract the actual invoice number from concatenated values like "100100" -> "100"
              # The pattern seems to be the invoice number repeated: 45 -> 45, 100 -> 100100
              # We need to find the original number that when repeated/concatenated gives us this value
              extract_invoice_number_from_concatenated(invoice_num_str)

            _ ->
              nil
          end
        end)

      nil ->
        nil
    end
  end

  defp extract_invoice_number_from_concatenated(invoice_num_str) do
    # Handle patterns like:
    # "45" -> "45" (already correct)
    # "100100" -> "100" (100 repeated)
    # "5252" -> "52" (52 repeated)

    num_length = String.length(invoice_num_str)

    cond do
      # If length is odd or <= 3, it's probably not concatenated
      num_length <= 3 || rem(num_length, 2) == 1 ->
        invoice_num_str

      # If length is even, check if it's a repeated number
      rem(num_length, 2) == 0 ->
        half_length = div(num_length, 2)
        first_half = String.slice(invoice_num_str, 0, half_length)
        second_half = String.slice(invoice_num_str, half_length, half_length)

        if first_half == second_half do
          # It's repeated, use the first half
          first_half
        else
          # Not repeated, use as-is
          invoice_num_str
        end

      true ->
        invoice_num_str
    end
  end

  defp find_date_in_cells(cells) do
    # Look for DateTime values in the cells
    flat_cells = List.flatten(cells)

    date_value =
      Enum.find(flat_cells, fn cell ->
        match?(%DateTime{}, cell) || match?(%NaiveDateTime{}, cell)
      end)

    case date_value do
      %NaiveDateTime{} = naive_dt ->
        NaiveDateTime.to_date(naive_dt)

      %DateTime{} = dt ->
        DateTime.to_date(dt)

      _ ->
        # Fallback: use current date if no date found
        Date.utc_today()
    end
  end

  defp extract_invoice_data_from_excel(file_path) do
    try do
      {:ok, pid} = Xlsxir.extract(file_path, 0)

      # Get all cells 
      cells = Xlsxir.get_list(pid)

      # Extract invoice number, date, and amount from cells
      invoice_number = find_invoice_number_in_cells(cells)
      date = find_date_in_cells(cells)
      amount = find_amount_in_cells(cells)

      Xlsxir.close(pid)

      if invoice_number && date do
        {:ok, invoice_number, date, amount}
      else
        {:error, "Could not find invoice number or date in Excel file"}
      end
    rescue
      e ->
        {:error, "Excel parsing failed: #{inspect(e)}"}
    end
  end

  defp find_amount_in_cells(cells) do
    # Look through all cells to find the invoice amount
    # The amount typically appears after "AMOUNT" or near "TOTAL"

    flat_cells = List.flatten(cells)

    # Find potential amounts - numbers that look like currency (not dates, not invoice numbers)
    potential_amounts =
      flat_cells
      |> Enum.filter(&is_number/1)
      |> Enum.filter(&(&1 > 0))
      # Reasonable upper bound for invoice amounts
      |> Enum.filter(&(&1 < 1_000_000))
      # Reject large integers (likely invoice numbers - most invoice numbers are > 99999)
      |> Enum.reject(&(is_integer(&1) && &1 > 99999))
      # Prefer floats over integers for amounts (amounts usually have decimals)
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
        # Find the most common amount (should appear exactly twice)
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

  defp create_invoice_record(invoice_number, date, amount, user_id) do
    attrs = %{
      "invoice_number" => invoice_number,
      "description" => "Imported historical invoice",
      "amount" => amount,
      "date" => date,
      "user_id" => to_string(user_id)
    }

    case Invoice.changeset(%Invoice{}, attrs) |> Repo.insert() do
      {:ok, invoice} ->
        {:ok, invoice}

      {:error, changeset} ->
        {:error, "database error: #{inspect(changeset.errors)}"}
    end
  end
end

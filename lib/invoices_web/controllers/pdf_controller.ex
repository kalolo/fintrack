defmodule InvoicesWeb.PdfController do
  use InvoicesWeb, :controller

  alias Invoices.Billing

  def show(conn, %{"id" => id}) do
    invoice = Billing.get_invoice!(id)

    # Generate PDF content
    case generate_invoice_pdf(invoice) do
      {:ok, pdf_binary} ->
        conn
        |> put_resp_content_type("application/pdf")
        |> put_resp_header("cache-control", "no-cache, no-store, must-revalidate")
        |> put_resp_header("pragma", "no-cache")
        |> put_resp_header("expires", "0")
        |> put_resp_header("content-length", "#{byte_size(pdf_binary)}")
        |> send_resp(200, pdf_binary)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to generate PDF: #{reason}")
        |> redirect(to: ~p"/invoices/#{id}")
    end
  end

  def download(conn, %{"id" => id}) do
    invoice = Billing.get_invoice!(id)

    # Generate PDF content
    case generate_invoice_pdf(invoice) do
      {:ok, pdf_binary} ->
        conn
        |> put_resp_content_type("application/pdf")
        |> put_resp_header(
          "content-disposition",
          ~s[inline; filename="invoice_#{invoice.invoice_number}.pdf"]
        )
        |> send_resp(200, pdf_binary)

      {:error, reason} ->
        conn
        |> put_flash(:error, "Failed to generate PDF: #{reason}")
        |> redirect(to: ~p"/invoices/#{id}")
    end
  end

  defp generate_invoice_pdf(invoice) do
    client_info = Billing.get_client_info()
    bill_to_info = Billing.get_bill_to_info()

    # Generate HTML content
    html_content = render_invoice_html(invoice, client_info, bill_to_info)

    # Generate PDF using ChromicPDF
    try do
      source = {:html, html_content}

      case ChromicPDF.print_to_pdf(source) do
        {:ok, base64_pdf} ->
          # ChromicPDF returns Base64-encoded PDF, decode it to binary
          case Base.decode64(base64_pdf) do
            {:ok, pdf_binary} -> {:ok, pdf_binary}
            :error -> {:error, "Failed to decode PDF from Base64"}
          end

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        {:error, "PDF generation failed: #{Exception.message(e)}"}
    end
  end

  defp render_invoice_html(invoice, client_info, bill_to_info) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Invoice #{invoice.invoice_number}</title>
      <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }

        @page {
          size: A4;
          margin: 0.5in;
        }

        body {
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
          line-height: 1.4;
          color: #374151;
          background: white;
          font-size: 11px;
          -webkit-font-smoothing: antialiased;
          -moz-osx-font-smoothing: grayscale;
        }

        .invoice-container {
          width: 100%;
          height: 100vh;
          padding: 0;
          background: white;
          display: flex;
          flex-direction: column;
        }

        /* Header Section */
        .header {
          text-align: center;
          margin-bottom: 24px;
          padding-bottom: 12px;
          border-bottom: 3px solid #142120ff;
        }

        .header h1 {
          font-size: 28px;
          font-weight: 700;
          color: #111827;
          margin: 0;
          letter-spacing: -0.025em;
        }

        .header .subtitle {
          font-size: 11px;
          color: #6b7280;
          margin-top: 4px;
          font-weight: 400;
        }

        /* Invoice Meta Section */
        .invoice-meta {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 16px;
          margin-bottom: 24px;
        }

        .meta-box {
          background: linear-gradient(135deg, #646565ff 0%, #060606ff 100%);
          color: #111;
          padding: 12px 16px;
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(40, 43, 43, 0.1);
        }

        .meta-label {
          font-size: 9px;
          font-weight: 600;
          margin-bottom: 4px;
          text-transform: uppercase;
          letter-spacing: 0.05em;
          opacity: 0.9;
        }

        .meta-value {
          font-size: 16px;
          font-weight: 700;
          letter-spacin g: -0.025em;
        }

        /* Parties Section */
        .parties {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 24px;
          margin-bottom: 24px;
        }

        .party-section {
          background: #f8fafc;
          border-radius: 8px;
          overflow: hidden;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        }

        .party-header {
          background: linear-gradient(135deg, #374151 0%, #1f2937 100%);
          color: white;
          padding: 8px 12px;
          font-weight: 600;
          font-size: 10px;
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }

        .party-content {
          padding: 12px;
          font-size: 10px;
          line-height: 1.5;
        }

        .party-content div {
          margin-bottom: 3px;
        }

        .party-content .label {
          font-weight: 600;
          color: #111;
          margin-right: 4px;
          display: inline-block;
          min-width: 60px;
        }

        .party-content .value {
          color: #111;
          font-weight: 400;
        }

        /* Services Table */
        .services-table {
          border-radius: 8px;
          overflow: hidden;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
          border: none;
          border-collapse: separate;
          border-spacing: 0;
          width: 100%;
          margin-bottom: 0;
          flex: 1;
        }

        .table-header {
          background: linear-gradient(135deg, #0d9488 0%, #0f766e 100%);
          color: white;
        }

        .table-header th {
          padding: 10px 12px;
          font-weight: 600;
          font-size: 10px;
          text-align: left;
          border: none;
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }

        .table-header th:nth-child(2),
        .table-header th:nth-child(3) {
          text-align: center;
        }

        .table-header th:nth-child(4) {
          text-align: right;
        }

        .service-row td {
          padding: 10px 12px;
          border-bottom: 1px solid #e5e7eb;
          font-size: 10px;
          vertical-align: top;
          background: white;
        }

        .service-row td:nth-child(1) {
          font-weight: 500;
          color: #111827;
        }

        .service-row td:nth-child(2),
        .service-row td:nth-child(3) {
          text-align: center;
          color: #6b7280;
        }

        .service-row td:nth-child(4) {
          text-align: right;
          font-weight: 600;
          color: #111827;
          font-size: 11px;
        }

        .empty-row td {
          padding: 4px 12px;
          border-bottom: 1px solid #f3f4f6;
          font-size: 10px;
          color: transparent;
          height: 18px;
          background: #fefefe;
        }

        .total-row {
          background: linear-gradient(135deg, #dbeafe 0%, #bfdbfe 100%);
        }

        .total-row td {
          padding: 12px;
          font-weight: 700;
          font-size: 12px;
          border: none;
          color: #000000ff;
        }

        .total-row td:nth-child(1) {
          text-align: right;
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }

        .total-row td:nth-child(2) {
          text-align: right;
          font-size: 14px;
        }

        /* Professional touches */
        .divider {
          height: 2px;
          background: linear-gradient(90deg, #0d9488 0%, #6b7280 100%);
          margin: 16px 0;
          border-radius: 1px;
        }

        /* Ensure everything fits on one page */
        .invoice-container,
        .parties,
        .services-table {
          page-break-inside: avoid;
        }
      </style>
    </head>
    <body>
      <div class="invoice-container">
        <!-- Header -->
        <div class="header">
          <h1>SERVICE INVOICE</h1>
          <div class="subtitle">Professional Services Invoice</div>
        </div>

        <!-- Invoice Number and Date -->
        <div class="invoice-meta">
          <div class="meta-box">
            <div class="meta-label">Invoice No.</div>
            <div class="meta-value">#{invoice.invoice_number}</div>
          </div>
          <div class="meta-box">
            <div class="meta-label">Issue Date</div>
            <div class="meta-value">#{Calendar.strftime(invoice.date, "%-d/%-m/%Y")}</div>
          </div>
        </div>

        <!-- Client and Bill To sections -->
        <div class="parties">
          <!-- Client -->
          <div class="party-section">
            <div class="party-header">Client Information</div>
            <div class="party-content">
              <div><span class="label">Name:</span><span class="value">#{client_info.name}</span></div>
              <div><span class="label">Address:</span><span class="value">#{client_info.address}</span></div>
              <div><span class="label"></span><span class="value">#{client_info.city_state_zip}</span></div>
              <div><span class="label">EIN:</span><span class="value">#{client_info.ein}</span></div>
            </div>
          </div>

          <!-- Bill To -->
          <div class="party-section">
            <div class="party-header">Billing Information</div>
            <div class="party-content">
              <div><span class="label">Name:</span><span class="value">#{bill_to_info.name}</span></div>
              <div><span class="label">SWIFT:</span><span class="value">#{bill_to_info.swift_bic}</span></div>
              <div><span class="label">Account:</span><span class="value">#{bill_to_info.account_number}</span></div>
              <div><span class="label">Bank:</span><span class="value">#{bill_to_info.bank_name}</span></div>
              <div style="font-size: 9px; margin-top: 4px; color: #6b7280;">#{bill_to_info.bank_address}</div>
            </div>
          </div>
        </div>

        <div class="divider"></div>

        <!-- Services Table -->
        <table class="services-table">
          <thead class="table-header">
            <tr>
              <th>Service Description</th>
              <th>Hours</th>
              <th>Rate</th>
              <th>Amount</th>
            </tr>
          </thead>
          <tbody>
            <tr class="service-row">
              <td>#{invoice.description}</td>
              <td>—</td>
              <td>—</td>
              <td>#{InvoicesWeb.Helpers.FormatHelper.format_currency(invoice.amount)}</td>
            </tr>
            #{Enum.map_join(1..4, "", fn _ -> """
      """ end)}
            <tr class="total-row">
              <td colspan="3">Total Amount</td>
              <td>#{InvoicesWeb.Helpers.FormatHelper.format_currency(invoice.amount)}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </body>
    </html>
    """
  end
end

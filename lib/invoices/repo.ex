defmodule Invoices.Repo do
  use Ecto.Repo,
    otp_app: :invoices,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 100
end

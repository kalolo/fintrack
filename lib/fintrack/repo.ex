defmodule FinTrack.Repo do
  use Ecto.Repo,
    otp_app: :fintrack,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 100
end

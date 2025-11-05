defmodule FinTrack.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FinTrackWeb.Telemetry,
      FinTrack.Repo,
      {DNSCluster, query: Application.get_env(:fintrack, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: FinTrack.PubSub},
      # ChromicPDF supervisor for PDF generation
      {ChromicPDF, session_pool: [size: 2]},
      # Start a worker by calling: FinTrack.Worker.start_link(arg)
      # {FinTrack.Worker, arg},
      # Start to serve requests, typically the last entry
      FinTrackWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FinTrack.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FinTrackWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

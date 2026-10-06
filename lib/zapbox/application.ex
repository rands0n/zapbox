defmodule Zapbox.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ZapboxWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:zapbox, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Zapbox.PubSub},
      Zapbox.Messages.Store,
      Zapbox.Controllers.Store,
      # Start a worker by calling: Zapbox.Worker.start_link(arg)
      # {Zapbox.Worker, arg},
      # Start to serve requests, typically the last entry
      ZapboxWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Zapbox.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ZapboxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

defmodule Loka.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LokaWeb.Telemetry,
      Loka.Repo,
      {DNSCluster, query: Application.get_env(:loka, :dns_cluster_query) || :ignore},
      {Oban,
       AshOban.config(
         Application.fetch_env!(:loka, :ash_domains),
         Application.fetch_env!(:loka, Oban)
       )},
      {Phoenix.PubSub, name: Loka.PubSub},
      # Start a worker by calling: Loka.Worker.start_link(arg)
      # {Loka.Worker, arg},
      # Start to serve requests, typically the last entry
      LokaWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :loka]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Loka.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LokaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

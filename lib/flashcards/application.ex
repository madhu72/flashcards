defmodule Flashcards.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FlashcardsWeb.Telemetry,
      Flashcards.Repo,
      {DNSCluster, query: Application.get_env(:flashcards, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Flashcards.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Flashcards.Finch},
      # Start a worker by calling: Flashcards.Worker.start_link(arg)
      # {Flashcards.Worker, arg},
      # Start to serve requests, typically the last entry
      FlashcardsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Flashcards.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FlashcardsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end

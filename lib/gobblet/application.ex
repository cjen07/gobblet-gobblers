defmodule Gobblet.Application do
  use Application

  alias Gobblet.Logic

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Gobblet.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Gobblet.Web.Endpoint, []),
      # Start your own worker by calling: Gobblet.Worker.start_link(arg1, arg2, arg3)
      # worker(Gobblet.Worker, [arg1, arg2, arg3]),
      supervisor(Logic.GameSupervisor, []),
      supervisor(Registry, [:unique, Registry.Gobblet]),
      worker(Logic.GameWatcher, [:games])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Gobblet.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

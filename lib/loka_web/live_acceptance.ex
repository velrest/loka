defmodule LokaWeb.LiveAcceptance do
  @moduledoc """
  Lets a LiveView started by a browser test use that test's Ecto sandbox
  connection. The test's browser sends the sandbox owner in its user agent.
  Only mounted when `:sql_sandbox` is configured (the test environment).
  """

  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:default, _params, _session, socket) do
    socket =
      assign_new(socket, :phoenix_ecto_sandbox, fn ->
        if connected?(socket), do: get_connect_info(socket, :user_agent)
      end)

    Phoenix.Ecto.SQL.Sandbox.allow(socket.assigns.phoenix_ecto_sandbox, Ecto.Adapters.SQL.Sandbox)
    {:cont, socket}
  end
end

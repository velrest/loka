defmodule LokaWeb.Plugs.RequireAdmin do
  @moduledoc """
  Rejects requests from actors that do not have the `admin?` flag set.

  Guards the admin tooling (LiveDashboard, Oban Web, AshAdmin, the mailbox
  preview). Non-admins get a 404 rather than a redirect so the existence of
  these routes is not advertised.

  This only protects the initial HTTP request — the dashboards are LiveViews,
  so their `live_session`s must additionally mount
  `{LokaWeb.LiveUserAuth, :live_admin_required}` to guard the websocket.
  """

  def init(opts), do: opts

  def call(%Plug.Conn{assigns: %{current_user: %{admin?: true}}} = conn, _opts), do: conn

  def call(conn, _opts) do
    raise Phoenix.Router.NoRouteError, conn: conn, router: LokaWeb.Router
  end
end

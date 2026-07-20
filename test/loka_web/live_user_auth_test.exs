defmodule LokaWeb.LiveUserAuthTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Support.UserHelpers
  alias LokaWeb.LiveUserAuth

  # The admin dashboards are LiveViews, so plugs only cover their initial HTTP
  # render. These exercise the websocket-side guard on its own.
  describe "on_mount :live_admin_required" do
    defp mount(session) do
      socket = %Phoenix.LiveView.Socket{endpoint: LokaWeb.Endpoint}
      LiveUserAuth.on_mount(:live_admin_required, %{}, session, socket)
    end

    # Build the session the way a real sign-in does, rather than hand-rolling
    # its shape — the format depends on the resource's token settings.
    defp session_for(user) do
      Phoenix.ConnTest.build_conn()
      |> UserHelpers.log_in_user(user)
      |> Plug.Conn.get_session()
    end

    test "continues for an admin" do
      admin = UserHelpers.create_admin()

      assert {:cont, socket} = mount(session_for(admin))
      assert socket.assigns.current_user.id == admin.id
    end

    test "halts for a signed-in non-admin" do
      assert {:halt, socket} = mount(session_for(UserHelpers.create_user()))
      assert socket.redirected == {:redirect, %{to: "/", status: 302}}
    end

    test "halts for an anonymous visitor" do
      assert {:halt, socket} = mount(%{})
      assert socket.redirected == {:redirect, %{to: "/", status: 302}}
    end
  end
end

defmodule LokaWeb.Features.UserSettingsTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Support.UserHelpers

  @password "password123"

  setup %{conn: conn} do
    user = UserHelpers.create_user(%{password: @password})
    logged_in_conn = UserHelpers.sign_in(conn, user.email, @password)
    %{user: user, conn: logged_in_conn}
  end

  describe "settings page for authenticated user" do
    test "renders user settings", %{conn: conn, user: user} do
      session =
        conn
        |> visit(~p"/me/settings")

      assert_has(session, "h1", text: "My Settings")

      if user.confirmed_at do
        assert_has(session, "span", text: "Yes")
      else
        assert_has(session, "span", text: "No")
      end
    end
  end

  describe "settings page for unauthenticated user" do
    test "redirects to sign-in page" do
      build_conn()
      |> visit(~p"/me/settings")
      |> assert_path(~p"/sign-in")
    end
  end
end

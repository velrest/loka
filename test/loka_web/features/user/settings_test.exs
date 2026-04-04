defmodule LokaWeb.Features.UserSettingsTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Accounts.User
  alias Loka.Support.UserHelpers
  import AshAuthentication.Test.Login

  setup %{conn: conn} do
    user = UserHelpers.create_user()
    logged_in_conn = login_user(conn, user)
    %{user: user, conn: logged_in_conn}
  end

  describe "settings page for authenticated user" do
    test "renders user settings", %{conn: conn, user: user} do
      response =
        conn
        |> visit(~p"/me/settings")

      assert response |> has_element?("h1", text: "My Settings")
      assert response |> has_element?("div", text: user.email)
      assert response |> has_element?("div", text: user.id)

      # Check for confirmed status
      if user.confirmed_at do
        assert response |> has_element?("span", text: "Yes")
      else
        assert response |> has_element?("span", text: "No")
      end
    end
  end

  describe "settings page for unauthenticated user" do
    test "redirects to sign-in page", %{conn: conn} do
      response =
        conn
        |> visit(~p"/me/settings")

      assert redirected_to(response) == ~p"/sign-in"
    end
  end
end

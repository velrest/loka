defmodule LokaWeb.Features.UserProfileTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Support.UserHelpers

  @password "password123"

  setup %{conn: conn} do
    user = UserHelpers.create_user(%{password: @password})
    logged_in_conn = UserHelpers.sign_in(conn, user.email, @password)
    %{user: user, conn: logged_in_conn}
  end

  describe "profile page for unauthenticated user" do
    test "redirects to sign-in page" do
      build_conn()
      |> visit(~p"/me")
      |> assert_path(~p"/sign-in")
    end
  end

  describe "profile page for authenticated user" do
    test "renders email and confirmation status", %{conn: conn, user: user} do
      conn
      |> visit(~p"/me")
      |> assert_has("h1", text: "Profil")
      |> assert_has("div", text: to_string(user.email))
    end
  end
end

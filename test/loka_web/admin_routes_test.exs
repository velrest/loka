defmodule LokaWeb.AdminRoutesTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Support.UserHelpers

  @admin_paths ["/admin", "/oban", "/dashboard"]

  describe "without an admin actor" do
    test "anonymous visitors get a 404", %{conn: conn} do
      for path <- @admin_paths do
        assert conn |> get(path) |> response(404)
      end
    end

    test "signed-in non-admins get a 404", %{conn: conn} do
      conn = UserHelpers.log_in_user(conn, UserHelpers.create_user())

      for path <- @admin_paths do
        assert conn |> get(path) |> response(404)
      end
    end
  end

  describe "with an admin actor" do
    setup %{conn: conn} do
      %{conn: UserHelpers.log_in_user(conn, UserHelpers.create_admin())}
    end

    # /oban is covered by the 404 tests above only — its LiveView needs the
    # Oban.Met instance, which does not run in the test environment.
    test "admin tools are reachable", %{conn: conn} do
      # LiveDashboard's root redirects to its default page.
      for path <- ["/admin", "/dashboard/home"] do
        assert conn |> get(path) |> response(200)
      end
    end
  end
end

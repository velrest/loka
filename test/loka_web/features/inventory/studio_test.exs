defmodule LokaWeb.Features.Inventory.StudioTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Support.UserHelpers

  @password "password123"

  setup %{conn: conn} do
    user = UserHelpers.create_user(%{password: @password})
    logged_in_conn = UserHelpers.sign_in(conn, user.email, @password)
    %{user: user, conn: logged_in_conn}
  end

  describe "inventory studio page without a studio" do
    test "redirects to /me/studio", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> assert_path(~p"/me/studio")
    end
  end

  describe "inventory studio page with an existing studio" do
    setup %{user: user} do
      {:ok, studio} = Loka.Studios.create_studio(%{name: "My Studio"}, actor: user)
      %{studio: studio}
    end

    test "renders the studio update form", %{conn: conn, studio: studio} do
      conn
      |> visit(~p"/inventory/studio")
      |> assert_has("h1", text: "Manage your studio")
      |> assert_has("input[name='studio[name]'][value='#{studio.name}']")
      |> assert_has("button", text: "Update studio")
    end

    test "updating the studio name saves and re-renders", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> fill_in("Studio name", with: "Renamed Studio")
      |> click_button("Update studio")
      |> assert_has("input[name='studio[name]'][value='Renamed Studio']")
    end

    test "shows archive button", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> assert_has("button", text: "Archive studio")
    end

    test "clicking archive opens confirm modal", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> click_button("Archive studio")
      |> assert_has("h3", text: "Archive your studio?")
      |> assert_has("button", text: "Yes, archive")
      |> assert_has("button", text: "Cancel")
    end

    test "cancelling the modal closes it", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> click_button("Archive studio")
      |> click_button("Cancel")
      |> refute_has("dialog.modal-open")
    end

    test "confirming archive redirects to /me/studio", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> click_button("Archive studio")
      |> click_button("Yes, archive")
      |> assert_path(~p"/me/studio")
    end
  end

  describe "archive authorization" do
    setup do
      other_user = UserHelpers.create_user(%{password: @password})
      {:ok, studio} = Loka.Studios.create_studio(%{name: "Other Studio"}, actor: other_user)
      %{studio: studio}
    end

    test "non-owner cannot archive another user's studio", %{studio: studio} do
      assert {:error, _} =
               Loka.Studios.archive_studio(studio, actor: UserHelpers.create_user())
    end
  end
end

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
      {:ok, studio} = Loka.Studios.create_studio(%{name: "My Studio", city: "Bern", postal_code: "3004"}, actor: user)
      %{studio: studio}
    end

    test "renders the studio update form", %{conn: conn, studio: studio} do
      conn
      |> visit(~p"/inventory/studio")
      |> assert_has("h1", text: "Studio verwalten")
      |> assert_has("input[name='studio[name]'][value='#{studio.name}']")
      |> assert_has("button", text: "Speichern")
    end

    test "updating the studio name saves and re-renders", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> fill_in("Studioname", with: "Renamed Studio")
      |> click_button("Speichern")
      |> assert_has("input[name='studio[name]'][value='Renamed Studio']")
    end

    test "renders description field", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> assert_has("textarea[name='studio[description]']")
    end

    test "updating description saves and re-renders", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> fill_in("Beschreibung", with: "Handgemachte Keramik aus Bern")
      |> click_button("Speichern")
      |> assert_has("textarea[name='studio[description]']", text: "Handgemachte Keramik aus Bern")
    end

    test "renders location card with map", %{conn: conn, studio: studio} do
      conn
      |> visit(~p"/inventory/studio")
      |> assert_has("h3", text: "Standort")
      |> assert_has("[data-lat='#{studio.latitude}']")
    end

    test "shows archive button", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> assert_has("button", text: "Studio archivieren")
    end

    test "clicking archive opens confirm modal", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> click_button("Studio archivieren")
      |> assert_has("h3", text: "Studio archivieren?")
      |> assert_has("button", text: "Ja, archivieren")
      |> assert_has("button", text: "Abbrechen")
    end

    test "cancelling the modal closes it", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> click_button("Studio archivieren")
      |> click_button("Abbrechen")
      |> refute_has("dialog.modal-open")
    end

    test "confirming archive redirects to /me/studio", %{conn: conn} do
      conn
      |> visit(~p"/inventory/studio")
      |> click_button("Studio archivieren")
      |> click_button("Ja, archivieren")
      |> assert_path(~p"/me/studio")
    end
  end

  describe "archive authorization" do
    setup do
      other_user = UserHelpers.create_user(%{password: @password})
      {:ok, studio} = Loka.Studios.create_studio(%{name: "Other Studio", city: "Basel", postal_code: "4000"}, actor: other_user)
      %{studio: studio}
    end

    test "non-owner cannot archive another user's studio", %{studio: studio} do
      assert {:error, _} =
               Loka.Studios.archive_studio(studio, actor: UserHelpers.create_user())
    end
  end
end

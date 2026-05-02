defmodule LokaWeb.Features.UserStudioTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Support.UserHelpers

  @password "password123"

  setup %{conn: conn} do
    user = UserHelpers.create_user(%{password: @password})
    logged_in_conn = UserHelpers.sign_in(conn, user.email, @password)
    %{user: user, conn: logged_in_conn}
  end

  describe "studio page for unauthenticated user" do
    test "redirects to sign-in page" do
      build_conn()
      |> visit(~p"/me/studio")
      |> assert_path(~p"/sign-in")
    end
  end

  describe "studio page with no existing studio" do
    test "renders empty state", %{conn: conn} do
      conn
      |> visit(~p"/me/studio")
      |> assert_has("h2", text: "Dein Studio wartet")
      |> assert_has("button", text: "Studio eröffnen")
    end

    test "clicking 'Studio eröffnen' shows the create form", %{conn: conn} do
      conn
      |> visit(~p"/me/studio")
      |> click_button("Studio eröffnen")
      |> assert_has("h1", text: "Studio eröffnen")
      |> assert_has("input[name='studio[name]']")
      |> assert_has("button", text: "Studio erstellen")
    end

    test "submitting without city shows validation error", %{conn: conn} do
      conn
      |> visit(~p"/me/studio")
      |> click_button("Studio eröffnen")
      |> fill_in("Studioname", with: "My Test Studio")
      |> click_button("Studio erstellen")
      |> assert_has("p.text-error")
    end

    test "submitting valid name and city creates studio and shows it", %{conn: conn} do
      conn
      |> visit(~p"/me/studio")
      |> click_button("Studio eröffnen")
      |> fill_in("Studioname", with: "My Test Studio")
      |> fill_in("PLZ", with: "6000")
      |> fill_in("Ort", with: "Luzern")
      |> click_button("Studio erstellen")
      |> assert_has("p", text: "My Test Studio")
      |> assert_has("p", text: "Aktiv")
    end
  end

  describe "studio page with existing studio" do
    setup %{user: user} do
      studio =
        Loka.Studios.create_studio!(
          %{name: "Existing Studio", city: "Genf", postal_code: "1200"},
          actor: user
        )

      %{studio: studio}
    end

    test "renders studio name", %{conn: conn, studio: studio} do
      conn
      |> visit(~p"/me/studio")
      |> assert_has("p", text: studio.name)
      |> assert_has("p", text: "Aktiv")
    end
  end
end

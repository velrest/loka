defmodule LokaWeb.Features.UserStudioTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Support.UserHelpers

  @password "password123"

  setup %{conn: conn} do
    user = UserHelpers.create_user(%{password: @password}) |> Ash.load!(:studio)
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
      |> assert_has("h2", text: "Your studio awaits")
      |> assert_has("button", text: "Open your studio")
    end

    test "clicking 'Open your studio' shows the create form", %{conn: conn} do
      conn
      |> visit(~p"/me/studio")
      |> click_button("Open your studio")
      |> assert_has("h1", text: "Name your studio")
      |> assert_has("input[name='studio[name]']")
      |> assert_has("button", text: "Create studio")
    end

    test "submitting empty form shows validation error", %{conn: conn} do
      conn
      |> visit(~p"/me/studio")
      |> click_button("Open your studio")
      |> click_button("Create studio")
      |> assert_has("p.text-error")
    end

    test "submitting valid name creates studio and shows it", %{conn: conn} do
      conn
      |> visit(~p"/me/studio")
      |> click_button("Open your studio")
      |> fill_in("Studio name", with: "My Test Studio")
      |> click_button("Create studio")
      |> assert_has("h1", text: "My Test Studio")
      |> assert_has("p", text: "Your studio is live.")
    end
  end

  describe "studio page with existing studio" do
    setup %{user: user} do
      studio =
        Loka.Studios.Studio
        |> Ash.Changeset.for_create(:create_studio, %{name: "Existing Studio"},
          actor: user,
          authorize?: false
        )
        |> Ash.create!()

      %{studio: studio}
    end

    test "renders studio name", %{conn: conn, studio: studio} do
      conn
      |> visit(~p"/me/studio")
      |> assert_has("h1", text: studio.name)
      |> assert_has("p", text: "Your studio is live.")
    end
  end
end

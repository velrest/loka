defmodule LokaWeb.Features.Shop.StudioTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Support.{InventoryHelpers, UserHelpers}

  setup do
    %{owner: owner, studio: studio} = UserHelpers.create_studio_owner()
    %{owner: owner, studio: studio}
  end

  describe "/shop/studio/:id" do
    test "renders studio name and city", %{conn: conn, studio: studio} do
      conn
      |> visit(~p"/shop/studio/#{studio.id}")
      |> assert_has("h1", text: studio.name)
      |> assert_has("span", text: studio.city)
    end

    test "shows back link to shop", %{conn: conn, studio: studio} do
      conn
      |> visit(~p"/shop/studio/#{studio.id}")
      |> assert_has("a", text: "← Zurück zum Markt")
    end

    test "shows empty state when no stock", %{conn: conn, studio: studio} do
      conn
      |> visit(~p"/shop/studio/#{studio.id}")
      |> assert_has("p", text: "Noch keine Artikel verfügbar.")
    end

    test "shows the studio's items", %{conn: conn, owner: owner, studio: studio} do
      item = InventoryHelpers.create_item(owner, %{name: "Kleine Vase"})

      conn
      |> visit(~p"/shop/studio/#{studio.id}")
      |> assert_has("[data-item='#{item.id}']")
      |> assert_has("a", text: "Kleine Vase")
    end

    test "shows items without stock, without add to cart",
         %{conn: conn, owner: owner, studio: studio} do
      item = InventoryHelpers.create_item(owner, %{name: "Krug", stock: nil})

      conn
      |> visit(~p"/shop/studio/#{studio.id}")
      |> assert_has("[data-item='#{item.id}']", text: "Nicht online erhältlich")
      |> refute_has("button", text: "In den Warenkorb")
    end

    test "redirects to / for unknown studio id", %{conn: conn} do
      conn
      |> visit(~p"/shop/studio/#{Ecto.UUID.generate()}")
      |> assert_path(~p"/")
    end
  end
end

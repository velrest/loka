defmodule LokaWeb.Features.Shop.StudioTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Support.UserHelpers

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
      |> assert_has("a", text: "← Zurück zum Shop")
    end

    test "shows empty state when no stock", %{conn: conn, studio: studio} do
      conn
      |> visit(~p"/shop/studio/#{studio.id}")
      |> assert_has("p", text: "Noch keine Artikel verfügbar.")
    end

    test "shows stock items when studio has them", %{conn: conn, owner: owner} do
      {:ok, stock} =
        Loka.Inventory.create_stock(
          %{name: "Kleine Vase", description: "Schöne Vase"},
          %{quantity: 2, price: Money.new(:CHF, 45)},
          actor: owner
        )

      conn
      |> visit(~p"/shop/studio/#{stock.studio_id}")
      |> assert_has("[data-item='#{stock.id}']")
      |> assert_has("a", text: "Kleine Vase")
    end

    test "redirects to / for unknown studio id", %{conn: conn} do
      conn
      |> visit(~p"/shop/studio/#{Ecto.UUID.generate()}")
      |> assert_path(~p"/")
    end
  end
end

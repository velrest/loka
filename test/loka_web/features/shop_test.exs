defmodule LokaWeb.Features.ShopTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Inventory

  setup %{conn: conn} do
    %{owner: user} = Loka.Support.UserHelpers.create_studio_owner()

    Inventory.create_stock!(
      %{name: "Cup", description: "A cup"},
      %{quantity: 1, price: Money.new(:CHF, 100)},
      actor: user
    )

    Inventory.create_stock!(
      %{name: "Bowl", description: "A bowl"},
      %{quantity: 2, price: Money.new(:CHF, 200)},
      actor: user
    )

    Inventory.create_stock!(
      %{name: "Plate", description: "A plate"},
      %{quantity: 3, price: Money.new(:CHF, 300)},
      actor: user
    )

    %{user: user, conn: conn}
  end

  describe "market page" do
    test "renders all stock entries", %{conn: conn} do
      conn
      |> visit(~p"/")
      |> assert_has("[data-item]", count: 3)
    end
  end

  describe "item page" do
    test "renders item name and description", %{conn: conn} do
      [stock | _] = Inventory.list_all_stock!(load: [item: :images])

      conn
      |> visit(~p"/shop/item/#{stock.item.id}")
      |> assert_has("h1", text: stock.item.name)
      |> assert_has("[data-testid='item-description']", text: stock.item.description)
    end

    test "renders item price", %{conn: conn} do
      [stock | _] = Inventory.list_all_stock!(load: [item: :images])

      conn
      |> visit(~p"/shop/item/#{stock.item.id}")
      |> assert_has("[data-testid='item-price']")
    end

    test "renders add to cart button", %{conn: conn} do
      [stock | _] = Inventory.list_all_stock!(load: [item: :images])

      conn
      |> visit(~p"/shop/item/#{stock.item.id}")
      |> assert_has("button", text: "In den Warenkorb")
    end

    test "unknown item id redirects to shop", %{conn: conn} do
      conn
      |> visit(~p"/shop/item/#{Ash.UUID.generate()}")
      |> assert_path("/")
    end
  end
end

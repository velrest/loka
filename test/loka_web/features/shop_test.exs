defmodule LokaWeb.Features.ShopTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Support.{InventoryHelpers, UserHelpers}

  setup %{conn: conn} do
    %{owner: owner} = UserHelpers.create_studio_owner()

    cup =
      InventoryHelpers.create_item(owner, %{
        name: "Cup",
        description: "A cup",
        stock: %{quantity: 1, price: Money.new(:CHF, 100)}
      })

    bowl =
      InventoryHelpers.create_item(owner, %{
        name: "Bowl",
        description: "A bowl",
        stock: %{quantity: 0, price: Money.new(:CHF, 200)}
      })

    plate =
      InventoryHelpers.create_item(owner, %{name: "Plate", description: "A plate", stock: nil})

    %{conn: conn, owner: owner, cup: cup, bowl: bowl, plate: plate}
  end

  describe "market page" do
    test "renders all items, including ones not in stock", %{conn: conn} do
      conn
      |> visit(~p"/")
      |> assert_has("[data-item]", count: 3)
    end

    test "leaves out archived items and archived studios", %{conn: conn, owner: owner, cup: cup} do
      %{owner: gone_owner, studio: gone_studio} = UserHelpers.create_studio_owner()
      gone = InventoryHelpers.create_item(gone_owner, %{name: "Gone"})
      :ok = Loka.Studios.archive_studio(gone_studio, actor: gone_owner)
      :ok = Loka.Inventory.archive_item(cup, actor: owner)

      conn
      |> visit(~p"/")
      |> assert_has("[data-item]", count: 2)
      |> refute_has("[data-item='#{cup.id}']")
      |> refute_has("[data-item='#{gone.id}']")
    end

    test "only items in stock get an add to cart button",
         %{conn: conn, owner: owner, cup: cup, bowl: bowl, plate: plate} do
      conn
      |> visit(~p"/")
      |> assert_has("[data-item='#{cup.id}'] button", text: "In den Warenkorb")
      |> refute_has("[data-item='#{bowl.id}'] button", text: "In den Warenkorb")
      |> refute_has("[data-item='#{plate.id}'] button", text: "In den Warenkorb")
      |> assert_has("[data-item='#{bowl.id}']", text: "Ausverkauft")
      |> assert_has("[data-item='#{plate.id}']", text: "Nicht online erhältlich")
    end
  end

  describe "item page" do
    test "renders item name and description", %{conn: conn, cup: cup} do
      conn
      |> visit(~p"/shop/item/#{cup.id}")
      |> assert_has("h1", text: cup.name)
      |> assert_has("[data-testid='item-description']", text: cup.description)
    end

    test "renders item price", %{conn: conn, cup: cup} do
      conn
      |> visit(~p"/shop/item/#{cup.id}")
      |> assert_has("[data-testid='item-price']", text: "CHF")
    end

    test "renders add to cart button", %{conn: conn, cup: cup} do
      conn
      |> visit(~p"/shop/item/#{cup.id}")
      |> assert_has("button", text: "In den Warenkorb")
    end

    test "sold out item shows no add to cart button", %{conn: conn, bowl: bowl} do
      conn
      |> visit(~p"/shop/item/#{bowl.id}")
      |> assert_has("h1", text: bowl.name)
      |> assert_has("[data-testid='item-price']", text: "Ausverkauft")
      |> refute_has("button", text: "In den Warenkorb")
    end

    test "item without stock shows name, studio and no price or button",
         %{conn: conn, plate: plate} do
      conn
      |> visit(~p"/shop/item/#{plate.id}")
      |> assert_has("h1", text: plate.name)
      |> assert_has("a", text: plate.studio.name)
      |> assert_has("[data-testid='item-price']", text: "Nicht online erhältlich")
      |> refute_has("[data-testid='item-price']", text: "CHF")
      |> refute_has("button", text: "In den Warenkorb")
    end

    test "archived item redirects to shop", %{conn: conn, owner: owner, cup: cup} do
      :ok = Loka.Inventory.archive_item(cup, actor: owner)

      conn
      |> visit(~p"/shop/item/#{cup.id}")
      |> assert_path("/")
    end

    test "unknown item id redirects to shop", %{conn: conn} do
      conn
      |> visit(~p"/shop/item/#{Ash.UUID.generate()}")
      |> assert_path("/")
    end
  end
end

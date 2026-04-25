defmodule Loka.Resources.Inventory.InventoryTest do
  use Loka.DataCase, async: true

  alias Loka.Inventory
  alias Loka.Support.UserHelpers

  setup do
    owner = UserHelpers.create_user()
    other = UserHelpers.create_user()

    studio = Loka.Studios.create_studio!(%{name: "My Studio"}, actor: owner)
    owner = Ash.load!(owner, :has_studio?)

    stock =
      Inventory.create_stock!(
        %{name: "Widget", description: "A widget"},
        %{quantity: 5, price: Money.new(:CHF, 100)},
        actor: owner
      )

    item = stock.item

    %{owner: owner, other: other, studio: studio, item: item, stock: stock}
  end

  describe "list_all_items" do
    test "returns all items", %{item: item} do
      assert {:ok, items} = Inventory.list_all_items()
      assert Enum.any?(items, &(&1.id == item.id))
    end
  end

  describe "create_stock" do
    test "actor with a studio can create stock with an inline item", %{owner: owner} do
      assert {:ok, stock} =
               Inventory.create_stock(
                 %{name: "New Item", description: "Desc"},
                 %{quantity: 1, price: Money.new(:CHF, 200)},
                 actor: owner
               )

      assert stock.quantity == 1
    end

    test "actor without a studio cannot create stock", %{other: other} do
      assert {:error, _} =
               Inventory.create_stock(
                 %{name: "New Item", description: "Desc"},
                 %{quantity: 1, price: Money.new(:CHF, 200)},
                 actor: other
               )
    end

    test "unauthenticated actor cannot create stock" do
      assert {:error, _} =
               Inventory.create_stock(
                 %{name: "New Item", description: "Desc"},
                 %{quantity: 1, price: Money.new(:CHF, 200)}
               )
    end
  end

  describe "update_item" do
    test "studio owner with stock can update an item", %{owner: owner, item: item} do
      assert {:ok, updated} = Inventory.update_item(item, %{name: "Updated"}, actor: owner)
      assert updated.name == "Updated"
    end

    test "actor without stock for the item cannot update it", %{other: other, item: item} do
      assert {:error, _} = Inventory.update_item(item, %{name: "Updated"}, actor: other)
    end

    test "unauthenticated actor cannot update an item", %{item: item} do
      assert {:error, _} = Inventory.update_item(item, %{name: "Updated"})
    end
  end

  describe "archive_item" do
    test "studio owner with stock can archive an item", %{owner: owner, item: item} do
      assert {:ok, _} = Inventory.archive_item(item, actor: owner)
    end

    test "actor without stock for the item cannot archive it", %{other: other, item: item} do
      assert {:error, _} = Inventory.archive_item(item, actor: other)
    end

    test "unauthenticated actor cannot archive an item", %{item: item} do
      assert {:error, _} = Inventory.archive_item(item)
    end
  end

  describe "get_item" do
    test "returns item with images and stock loaded", %{item: item} do
      assert {:ok, loaded} = Inventory.get_item(item.id)
      assert loaded.id == item.id
      assert %Ash.NotLoaded{} != loaded.images
      assert %Ash.NotLoaded{} != loaded.stock
    end

    test "returns nil for unknown id" do
      assert {:ok, nil} = Inventory.get_item(Ash.UUID.generate())
    end
  end
end

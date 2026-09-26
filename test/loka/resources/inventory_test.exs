defmodule Loka.Resources.Inventory.InventoryTest do
  use Loka.DataCase, async: true

  alias Loka.Inventory
  alias Loka.Support.{InventoryHelpers, UserHelpers}

  setup do
    %{owner: owner, studio: studio} = UserHelpers.create_studio_owner()
    %{owner: other_owner} = UserHelpers.create_studio_owner()
    other = UserHelpers.create_user()

    item = InventoryHelpers.create_item(owner)

    %{owner: owner, other_owner: other_owner, other: other, studio: studio, item: item}
  end

  describe "list_all_items" do
    test "returns all items, including ones without stock", %{owner: owner, item: item} do
      unlisted = InventoryHelpers.create_item(owner, %{stock: nil})

      assert {:ok, items} = Inventory.list_all_items()
      ids = Enum.map(items, & &1.id)
      assert item.id in ids
      assert unlisted.id in ids
    end

    test "leaves out archived items", %{owner: owner, item: item} do
      :ok = Inventory.archive_item(item, actor: owner)

      refute Enum.any?(Inventory.list_all_items!(), &(&1.id == item.id))
    end
  end

  describe "list_studio_items" do
    test "returns only that studio's items", %{studio: studio, other_owner: other_owner} do
      theirs = InventoryHelpers.create_item(other_owner)

      ids = studio.id |> Inventory.list_studio_items!() |> Enum.map(& &1.id)
      refute theirs.id in ids
      assert length(ids) == 1
    end
  end

  describe "create_item" do
    test "creates the item in the actor's own studio", %{owner: owner, studio: studio} do
      assert {:ok, item} =
               Inventory.create_item(%{name: "New Item", description: "Desc"}, actor: owner)

      assert item.studio_id == studio.id
    end

    test "creates the item with stock when given", %{owner: owner} do
      assert {:ok, item} =
               Inventory.create_item(
                 %{
                   name: "New Item",
                   description: "Desc",
                   stock: %{quantity: 1, price: Money.new(:CHF, 200)}
                 },
                 actor: owner
               )

      item = Ash.load!(item, [:stock, :in_stock?])
      assert item.stock.quantity == 1
      assert item.in_stock?
    end

    test "an item without stock is not in stock", %{owner: owner} do
      item = InventoryHelpers.create_item(owner, %{stock: nil})

      assert item.stock == nil
      refute item.in_stock?
    end

    test "an item with no pieces left is not in stock", %{owner: owner} do
      item =
        InventoryHelpers.create_item(owner, %{stock: %{quantity: 0, price: Money.new(:CHF, 1)}})

      refute item.in_stock?
    end

    test "the studio can't be chosen by the actor", %{owner: owner, studio: studio} do
      %{studio: other_studio} = UserHelpers.create_studio_owner()

      assert {:error, _} =
               Inventory.create_item(
                 %{name: "New Item", description: "Desc", studio_id: other_studio.id},
                 actor: owner
               )

      assert Enum.all?(
               Inventory.list_studio_items!(other_studio.id),
               &(&1.studio_id != studio.id)
             )
    end

    test "actor without a studio cannot create an item", %{other: other} do
      assert {:error, %Ash.Error.Forbidden{}} =
               Inventory.create_item(%{name: "New Item", description: "Desc"}, actor: other)
    end

    test "unauthenticated actor cannot create an item" do
      assert {:error, %Ash.Error.Forbidden{}} =
               Inventory.create_item(%{name: "New Item", description: "Desc"})
    end
  end

  describe "update_item" do
    test "studio owner can update an item", %{owner: owner, item: item} do
      assert {:ok, updated} = Inventory.update_item(item, %{name: "Updated"}, actor: owner)
      assert updated.name == "Updated"
    end

    test "owner of another studio cannot update it", %{other_owner: other_owner, item: item} do
      assert {:error, _} = Inventory.update_item(item, %{name: "Updated"}, actor: other_owner)
    end

    test "actor without a studio cannot update it", %{other: other, item: item} do
      assert {:error, _} = Inventory.update_item(item, %{name: "Updated"}, actor: other)
    end

    test "unauthenticated actor cannot update an item", %{item: item} do
      assert {:error, _} = Inventory.update_item(item, %{name: "Updated"})
    end
  end

  describe "archive_item" do
    test "studio owner can archive an item, which archives its stock too",
         %{owner: owner, item: item} do
      stock_id = item.stock.id

      assert :ok = Inventory.archive_item(item, actor: owner)
      assert {:error, %Ash.Error.Invalid{}} = Ash.get(Loka.Inventory.Stock, stock_id)
    end

    test "owner of another studio cannot archive it", %{other_owner: other_owner, item: item} do
      assert {:error, _} = Inventory.archive_item(item, actor: other_owner)
    end

    test "unauthenticated actor cannot archive an item", %{item: item} do
      assert {:error, _} = Inventory.archive_item(item)
    end
  end

  describe "get_own_item" do
    test "returns the item for its studio's owner", %{owner: owner, item: item} do
      assert {:ok, %{id: id}} = Inventory.get_own_item(item.id, actor: owner)
      assert id == item.id
    end

    test "returns nil for another studio's owner", %{other_owner: other_owner, item: item} do
      assert {:ok, nil} = Inventory.get_own_item(item.id, actor: other_owner)
    end

    test "requires an actor", %{item: item} do
      assert {:error, %Ash.Error.Invalid{}} = Inventory.get_own_item(item.id)
    end
  end

  describe "get_item" do
    test "returns item with images, stock and studio loaded", %{item: item} do
      assert {:ok, loaded} = Inventory.get_item(item.id)
      assert loaded.id == item.id
      assert is_list(loaded.images)
      assert loaded.stock.id == item.stock.id
      assert loaded.studio.id == item.studio_id
    end

    test "returns nil for unknown id" do
      assert {:ok, nil} = Inventory.get_item(Ash.UUID.generate())
    end
  end
end

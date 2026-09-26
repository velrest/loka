defmodule Loka.Resources.StockTest do
  use Loka.DataCase, async: true

  alias Loka.Inventory
  alias Loka.Support.{InventoryHelpers, UserHelpers}

  @price Money.new(:CHF, 500)

  setup do
    %{owner: owner} = UserHelpers.create_studio_owner()
    %{owner: other_owner} = UserHelpers.create_studio_owner()
    other = UserHelpers.create_user()

    %{owner: owner, other_owner: other_owner, other: other}
  end

  describe "create_stock" do
    setup %{owner: owner} do
      %{item: InventoryHelpers.create_item(owner, %{stock: nil})}
    end

    test "owner can put their item on sale", %{owner: owner, item: item} do
      assert {:ok, stock} =
               Inventory.create_stock(item.id, %{quantity: 10, price: @price}, actor: owner)

      assert stock.item_id == item.id
      assert stock.quantity == 10
      assert stock.price == @price
    end

    test "owner of another studio cannot create stock for the item",
         %{other_owner: other_owner, item: item} do
      assert {:error, %Ash.Error.Forbidden{}} =
               Inventory.create_stock(item.id, %{quantity: 10, price: @price}, actor: other_owner)
    end

    test "actor without a studio cannot create stock", %{other: other, item: item} do
      assert {:error, %Ash.Error.Forbidden{}} =
               Inventory.create_stock(item.id, %{quantity: 10, price: @price}, actor: other)
    end

    test "unauthenticated actor cannot create stock", %{item: item} do
      assert {:error, %Ash.Error.Forbidden{}} =
               Inventory.create_stock(item.id, %{quantity: 10, price: @price})
    end

    test "quantity must be zero or greater", %{owner: owner, item: item} do
      assert {:error, error} =
               Inventory.create_stock(item.id, %{quantity: -1, price: @price}, actor: owner)

      assert Enum.any?(error.errors, &match?(%{field: :quantity}, &1))
    end

    test "an item can't have two current stocks", %{owner: owner, item: item} do
      Inventory.create_stock!(item.id, %{quantity: 10, price: @price}, actor: owner)

      assert {:error, _} =
               Inventory.create_stock(item.id, %{quantity: 5, price: @price}, actor: owner)
    end

    test "an item can be re-listed after its stock was archived", %{owner: owner, item: item} do
      stock = Inventory.create_stock!(item.id, %{quantity: 10, price: @price}, actor: owner)
      :ok = Inventory.archive_stock(stock, actor: owner)

      new_price = Money.new(:CHF, 650)

      assert {:ok, relisted} =
               Inventory.create_stock(item.id, %{quantity: 3, price: new_price}, actor: owner)

      item = Ash.load!(item, :stock)
      assert item.stock.id == relisted.id
      assert item.stock.price == new_price
    end
  end

  describe "update_stock" do
    setup %{owner: owner} do
      %{stock: InventoryHelpers.create_item(owner).stock}
    end

    test "studio owner can update quantity and price in place", %{owner: owner, stock: stock} do
      assert {:ok, updated} =
               Inventory.update_stock(stock, %{quantity: 20, price: Money.new(:CHF, 999)},
                 actor: owner
               )

      assert updated.id == stock.id
      assert updated.quantity == 20
      assert updated.price == Money.new(:CHF, 999)
    end

    test "owner of another studio cannot update stock",
         %{other_owner: other_owner, stock: stock} do
      assert {:error, _} =
               Inventory.update_stock(stock, %{quantity: 20}, actor: other_owner)
    end

    test "non-owner cannot update stock", %{other: other, stock: stock} do
      assert {:error, _} = Inventory.update_stock(stock, %{quantity: 20}, actor: other)
    end

    test "unauthenticated actor cannot update stock", %{stock: stock} do
      assert {:error, _} = Inventory.update_stock(stock, %{quantity: 20})
    end
  end

  describe "archive_stock" do
    setup %{owner: owner} do
      item = InventoryHelpers.create_item(owner)
      %{item: item, stock: item.stock}
    end

    test "studio owner can archive stock, taking the item off sale",
         %{owner: owner, item: item, stock: stock} do
      assert :ok = Inventory.archive_stock(stock, actor: owner)

      item = Ash.load!(item, [:stock, :in_stock?])
      assert item.stock == nil
      refute item.in_stock?
    end

    test "non-owner cannot archive stock", %{other: other, stock: stock} do
      assert {:error, _} = Inventory.archive_stock(stock, actor: other)
    end

    test "unauthenticated actor cannot archive stock", %{stock: stock} do
      assert {:error, _} = Inventory.archive_stock(stock)
    end
  end
end

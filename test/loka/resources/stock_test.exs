defmodule Loka.Resources.StockTest do
  use Loka.DataCase, async: true

  alias Loka.Inventory
  alias Loka.Support.UserHelpers

  setup do
    owner = UserHelpers.create_user()
    other = UserHelpers.create_user()

    {:ok, studio} = Loka.Studios.create_studio(%{name: "My Studio"}, actor: owner)

    %{owner: owner, other: other, studio: studio}
  end

  defp create_stock(owner) do
    Inventory.create_stock(
      %{
        quantity: 10,
        price: Money.new(:CHF, 500),
        item: %{name: "Widget", description: "A widget"}
      },
      actor: owner
    )
  end

  describe "create_stock" do
    test "owner with a studio can create stock with an inline item", %{owner: owner} do
      assert {:ok, stock} = create_stock(owner)
      assert stock.quantity == 10
      assert stock.price == Money.new(:CHF, 500)
    end

    test "actor without a studio cannot create stock", %{other: other} do
      assert {:error, _} = create_stock(other)
    end

    test "unauthenticated actor cannot create stock" do
      assert {:error, _} =
               Inventory.create_stock(%{
                 quantity: 10,
                 price: Money.new(:CHF, 500),
                 item: %{name: "Widget", description: "A widget"}
               })
    end

    test "quantity must be zero or greater", %{owner: owner} do
      assert {:error, error} =
               Inventory.create_stock(
                 %{
                   quantity: -1,
                   price: Money.new(:CHF, 500),
                   item: %{name: "Widget", description: "A widget"}
                 },
                 actor: owner
               )

      assert Enum.any?(error.errors, &match?(%{field: :quantity}, &1))
    end
  end

  describe "update_stock" do
    setup %{owner: owner} do
      {:ok, stock} = create_stock(owner)
      %{stock: stock}
    end

    test "studio owner can update quantity and price", %{owner: owner, stock: stock} do
      assert {:ok, updated} =
               Inventory.update_stock(stock, %{quantity: 20, price: Money.new(:CHF, 999)},
                 actor: owner
               )

      assert updated.quantity == 20
      assert updated.price == Money.new(:CHF, 999)
    end

    test "non-owner cannot update stock", %{other: other, stock: stock} do
      assert {:error, _} =
               Inventory.update_stock(stock, %{quantity: 20, price: Money.new(:CHF, 999)},
                 actor: other
               )
    end

    test "unauthenticated actor cannot update stock", %{stock: stock} do
      assert {:error, _} =
               Inventory.update_stock(stock, %{quantity: 20, price: Money.new(:CHF, 999)})
    end
  end

  describe "archive_stock" do
    setup %{owner: owner} do
      {:ok, stock} = create_stock(owner)
      %{stock: stock}
    end

    test "studio owner can archive stock", %{owner: owner, stock: stock} do
      assert {:ok, _} = Inventory.archive_stock(stock, actor: owner)
    end

    test "non-owner cannot archive stock", %{other: other, stock: stock} do
      assert {:error, _} = Inventory.archive_stock(stock, actor: other)
    end

    test "unauthenticated actor cannot archive stock", %{stock: stock} do
      assert {:error, _} = Inventory.archive_stock(stock)
    end
  end
end

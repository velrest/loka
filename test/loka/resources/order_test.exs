defmodule Loka.Resources.OrderTest do
  use Loka.DataCase, async: true

  alias Loka.Commerce
  alias Loka.Support.UserHelpers

  setup do
    %{owner: owner} = UserHelpers.create_studio_owner()
    buyer = UserHelpers.create_user()
    other = UserHelpers.create_user()

    stock =
      Loka.Inventory.create_stock!(
        %{name: "Widget", description: "A widget"},
        %{quantity: 10, price: Money.new(:CHF, 500)},
        actor: owner
      )

    %{owner: owner, buyer: buyer, other: other, stock: stock}
  end

  defp lines(stock) do
    [%{stock_id: stock.id, unit_price: stock.price, quantity: 2}]
  end

  describe "place_order" do
    test "authenticated user can place an order", %{buyer: buyer, stock: stock} do
      assert {:ok, order} = Commerce.place_order(lines(stock), actor: buyer)
      assert order.status == :pending
    end

    test "order is linked to the actor", %{buyer: buyer, stock: stock} do
      {:ok, order} = Commerce.place_order(lines(stock), actor: buyer)
      order = Ash.load!(order, :order_lines, actor: buyer)
      assert length(order.order_lines) == 1
      assert hd(order.order_lines).unit_price == Money.new(:CHF, 500)
      assert hd(order.order_lines).quantity == 2
    end

    test "unauthenticated actor cannot place an order", %{stock: stock} do
      assert {:error, _} = Commerce.place_order(lines(stock))
    end

    test "quantity must be at least 1", %{buyer: buyer, stock: stock} do
      bad_lines = [%{stock_id: stock.id, unit_price: stock.price, quantity: 0}]
      assert {:error, error} = Commerce.place_order(bad_lines, actor: buyer)
      assert Enum.any?(error.errors, &match?(%{field: :quantity}, &1))
    end
  end

  describe "list_user_orders" do
    setup %{buyer: buyer, other: other, stock: stock} do
      {:ok, order} = Commerce.place_order(lines(stock), actor: buyer)
      {:ok, _other_order} = Commerce.place_order(lines(stock), actor: other)
      %{order: order}
    end

    test "only returns orders belonging to the actor", %{buyer: buyer, order: order} do
      {:ok, orders} = Commerce.list_user_orders(actor: buyer)
      assert length(orders) == 1
      assert hd(orders).id == order.id
    end
  end

  describe "get_order" do
    setup %{buyer: buyer, stock: stock} do
      {:ok, order} = Commerce.place_order(lines(stock), actor: buyer)
      %{order: order}
    end

    test "buyer can get their own order", %{buyer: buyer, order: order} do
      assert {:ok, fetched} = Commerce.get_order(order.id, actor: buyer)
      assert fetched.id == order.id
    end

    test "other user cannot get the order", %{other: other, order: order} do
      assert {:ok, nil} = Commerce.get_order(order.id, actor: other)
    end
  end

  describe "cancel" do
    setup %{buyer: buyer, stock: stock} do
      {:ok, order} = Commerce.place_order(lines(stock), actor: buyer)
      %{order: order}
    end

    test "buyer can cancel their own order", %{buyer: buyer, order: order} do
      assert {:ok, cancelled} =
               Loka.Commerce.Order
               |> Ash.get!(order.id, actor: buyer)
               |> Ash.Changeset.for_update(:cancel, %{}, actor: buyer)
               |> Ash.update()

      assert cancelled.status == :cancelled
    end

    test "other user cannot cancel the order", %{other: other, order: order} do
      order_loaded = Ash.get!(Loka.Commerce.Order, order.id, authorize?: false)

      assert {:error, _} =
               order_loaded
               |> Ash.Changeset.for_update(:cancel, %{}, actor: other)
               |> Ash.update()
    end
  end

  describe "mark_paid" do
    setup %{buyer: buyer, stock: stock} do
      {:ok, order} = Commerce.place_order(lines(stock), actor: buyer)
      %{order: order}
    end

    test "studio owner can mark order as paid", %{owner: owner, order: order} do
      order_loaded = Ash.get!(Loka.Commerce.Order, order.id, authorize?: false)

      assert {:ok, paid} =
               order_loaded
               |> Ash.Changeset.for_update(:mark_paid, %{}, actor: owner)
               |> Ash.update()

      assert paid.status == :paid
    end

    test "buyer cannot mark own order as paid", %{buyer: buyer, order: order} do
      order_loaded = Ash.get!(Loka.Commerce.Order, order.id, authorize?: false)

      assert {:error, _} =
               order_loaded
               |> Ash.Changeset.for_update(:mark_paid, %{}, actor: buyer)
               |> Ash.update()
    end
  end

  describe "fulfil" do
    setup %{buyer: buyer, owner: owner, stock: stock} do
      {:ok, order} = Commerce.place_order(lines(stock), actor: buyer)
      order_loaded = Ash.get!(Loka.Commerce.Order, order.id, authorize?: false)

      {:ok, paid} =
        order_loaded |> Ash.Changeset.for_update(:mark_paid, %{}, actor: owner) |> Ash.update()

      %{order: paid}
    end

    test "studio owner can fulfil a paid order", %{owner: owner, order: order} do
      assert {:ok, fulfilled} =
               order |> Ash.Changeset.for_update(:fulfil, %{}, actor: owner) |> Ash.update()

      assert fulfilled.status == :fulfilled
    end

    test "buyer cannot fulfil the order", %{buyer: buyer, order: order} do
      assert {:error, _} =
               order |> Ash.Changeset.for_update(:fulfil, %{}, actor: buyer) |> Ash.update()
    end
  end
end

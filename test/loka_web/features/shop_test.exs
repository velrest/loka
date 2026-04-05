defmodule LokaWeb.Features.ShopTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Inventory

  setup %{conn: conn} do
    %{owner: user} = Loka.Support.UserHelpers.create_studio_owner()

    Inventory.create_stock!(
      %{quantity: 1, price: Money.new(:CHF, 100), item: %{name: "Cup", description: "A cup"}},
      actor: user
    )

    Inventory.create_stock!(
      %{quantity: 2, price: Money.new(:CHF, 200), item: %{name: "Bowl", description: "A bowl"}},
      actor: user
    )

    Inventory.create_stock!(
      %{quantity: 3, price: Money.new(:CHF, 300), item: %{name: "Plate", description: "A plate"}},
      actor: user
    )

    %{user: user, conn: conn}
  end

  describe "landing page" do
    test "renders all stock entries", %{conn: conn} do
      conn
      |> visit(~p"/")
      |> assert_has("[data-item]", count: 3)
    end
  end
end

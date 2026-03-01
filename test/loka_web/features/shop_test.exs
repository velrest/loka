defmodule LokaWeb.Features.ShopTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Inventory
  # Might need this pretty soon
  # alias Loka.Support.UserHelpers

  setup %{conn: conn} do
    user = Loka.Support.UserHelpers.create_user()

    Inventory.create_item!(%{name: "Test", description: "Test", price: Money.new(:CHF, 100)},
      actor: user
    )

    Inventory.create_item!(%{name: "Test", description: "Test", price: Money.new(:CHF, 100)},
      actor: user
    )

    Inventory.create_item!(%{name: "Test", description: "Test", price: Money.new(:CHF, 100)},
      actor: user
    )

    %{user: user, conn: conn}
  end

  describe "landing page" do
    test "renders all items", %{conn: conn} do
      conn
      |> visit(~p"/")
      |> assert_has("[data-item]", count: 3)
    end
  end
end

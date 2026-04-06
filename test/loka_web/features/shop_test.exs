defmodule LokaWeb.Features.ShopTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Inventory

  setup %{conn: conn} do
    %{owner: user, studio: studio} = Loka.Support.UserHelpers.create_studio_owner()

    Inventory.create_stock!(
      %{name: "Cup", description: "A cup"},
      studio.id,
      %{quantity: 1, price: Money.new(:CHF, 100)}, actor: user)

    Inventory.create_stock!(
      %{name: "Bowl", description: "A bowl"},
      studio.id,
      %{quantity: 2, price: Money.new(:CHF, 200)}, actor: user)

    Inventory.create_stock!(
      %{name: "Plate", description: "A plate"},
      studio.id,
      %{quantity: 3, price: Money.new(:CHF, 300)}, actor: user)

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

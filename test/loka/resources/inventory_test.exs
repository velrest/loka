defmodule Loka.Resources.Inventory.InventoryTest do
  use Loka.DataCase

  alias Loka.Inventory

  setup do
    user = Loka.Support.UserHelpers.create_user()

    Inventory.create_item!(%{name: "Test", description: "Test", price: Money.new(:CHF, 100)},
      actor: user
    )

    %{user: user}
  end

  test "list_all_items/0 lists all items" do
    items = Inventory.list_all_items!()
    assert Enum.count(items) == 1
  end
end

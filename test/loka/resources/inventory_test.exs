defmodule Loka.Resources.Inventory.InventoryTest do
  use Loka.DataCase

  alias Ash.Error.Forbidden
  alias Loka.Inventory

  setup do
    :ok
  end

  test "list_all_items/0 lists all items" do
    items = Inventory.list_all_items!()
    assert Enum.count(items) == 10
  end
end

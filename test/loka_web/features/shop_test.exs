defmodule LokaWeb.Features.ShopTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Inventory
  # Might need this pretty soon
  # alias Loka.Support.UserHelpers

  setup %{conn: conn} do
    :ok
  end

  describe "landing page" do
    test "renders all items" do
      assert 1 = 1
    end
  end
end

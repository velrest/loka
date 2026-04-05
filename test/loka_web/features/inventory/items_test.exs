defmodule LokaWeb.Features.Inventory.ItemsTest do
  use LokaWeb.ConnCase, async: true

  alias Loka.Support.UserHelpers

  @password "password123"

  setup %{conn: conn} do
    user = UserHelpers.create_user(%{password: @password})
    {:ok, _studio} = Loka.Studios.create_studio(%{name: "My Studio"}, actor: user)
    logged_in = UserHelpers.sign_in(conn, user.email, @password)
    %{user: user, conn: logged_in}
  end

  describe "/inventory/items/new (create mode)" do
    test "renders creation form with item and stock fields", %{conn: conn} do
      conn
      |> visit(~p"/inventory/items/new")
      |> assert_has("h1", text: "New item")
      |> assert_has("input[name='form[item][name]']")
      |> assert_has("input[name='form[item][description]']")
      |> assert_has("input[name='form[price]']")
      |> assert_has("input[name='form[quantity]']")
    end

    test "back link points to /inventory/items", %{conn: conn} do
      conn
      |> visit(~p"/inventory/items/new")
      |> assert_has("a", text: "← Back to items")
    end
  end

  describe "/inventory/items/:id (edit mode)" do
    setup %{user: user} do
      {:ok, stock} =
        Loka.Inventory.create_stock(
          %{
            quantity: 3,
            price: Money.new(:CHF, 150),
            item: %{name: "Bowl", description: "Ceramic bowl"}
          },
          actor: user
        )

      %{stock: stock}
    end

    test "renders item and stock forms", %{conn: conn, stock: stock} do
      conn
      |> visit(~p"/inventory/items/#{stock.id}")
      |> assert_has("h1", text: "Bowl")
      |> assert_has("input[name='item[name]'][value='Bowl']")
      |> assert_has("input[name='stock[price]']")
    end

    test "saving item details updates the item", %{conn: conn, stock: stock} do
      conn
      |> visit(~p"/inventory/items/#{stock.id}")
      |> fill_in("Name", with: "Ceramic Bowl")
      |> click_button("Save item details")
      |> assert_has("input[name='item[name]'][value='Ceramic Bowl']")
    end
  end

  describe "/inventory/items list" do
    test "renders the items table header", %{conn: conn} do
      conn
      |> visit(~p"/inventory/items")
      |> assert_has("h1", text: "Items")
    end

    test "'New item' button navigates to /inventory/items/new", %{conn: conn} do
      conn
      |> visit(~p"/inventory/items")
      |> click_link("New item")
      |> assert_path(~p"/inventory/items/new")
    end

    test "does not render an inline creation form", %{conn: conn} do
      conn
      |> visit(~p"/inventory/items")
      |> refute_has("form")
    end
  end
end

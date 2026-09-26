defmodule LokaWeb.AddToCartComponentTest do
  use LokaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Loka.Commerce
  alias Loka.Support.{InventoryHelpers, UserHelpers}

  setup do
    %{owner: owner} = UserHelpers.create_studio_owner()
    %{item: InventoryHelpers.create_item(owner)}
  end

  defp click_add(view, item, cart_id \\ "") do
    view
    |> element("#add-to-cart-#{item.id}")
    |> render_hook("add_to_cart", %{"item_id" => item.id, "cart_id" => cart_id})
  end

  defp item_count(cart_id) do
    {:ok, cart} = Ash.get(Commerce.Cart, cart_id, load: :item_count)
    cart.item_count
  end

  describe "anonymous visitor" do
    test "the first click creates an anonymous cart and replies with its id",
         %{conn: conn, item: item} do
      {:ok, view, _html} = live(conn, ~p"/")
      click_add(view, item)

      assert_reply(view, %{cart_id: cart_id, anonymous: true})
      assert {:ok, %{id: ^cart_id}} = Commerce.get_anonymous_cart(cart_id)
      assert item_count(cart_id) == 1
    end

    test "the next click with the remembered id reuses that cart", %{conn: conn, item: item} do
      {:ok, cart} = Commerce.create_cart()
      {:ok, view, _html} = live(conn, ~p"/")

      click_add(view, item, cart.id)
      click_add(view, item, cart.id)

      assert_reply(view, %{cart_id: cart_id, anonymous: true})
      assert cart_id == cart.id
      assert item_count(cart.id) == 2
    end
  end

  describe "signed-in user" do
    setup %{conn: conn} do
      user = UserHelpers.create_user()
      %{user: user, conn: UserHelpers.log_in_user(conn, user)}
    end

    test "clicking adds to the user's cart and updates the widget",
         %{conn: conn, user: user, item: item} do
      {:ok, view, _html} = live(conn, ~p"/")
      click_add(view, item)

      assert_reply(view, %{anonymous: false})
      cart = Commerce.get_user_cart!(actor: user, load: :item_count)
      assert cart.item_count == 1

      widget = find_live_child(view, "cart-widget")
      assert render(widget) =~ "badge"
    end
  end
end

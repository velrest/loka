defmodule LokaWeb.Shop.CartWidgetLiveTest do
  use LokaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Loka.Commerce
  alias Loka.Support.{InventoryHelpers, UserHelpers}

  @password "password123"

  defp cart_widget_html(view) do
    view |> find_live_child("cart-widget") |> render()
  end

  describe "anonymous user" do
    test "market page loads without redirect", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "Loka"
    end

    test "cart widget is hidden on initial load", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      refute cart_widget_html(view) =~ "dropdown dropdown-end"
    end

    test "cart widget appears after load_anonymous_cart with valid id", %{conn: conn} do
      {:ok, anon_cart} = Commerce.create_cart()

      {:ok, view, _html} = live(conn, ~p"/")
      widget = find_live_child(view, "cart-widget")
      render_hook(widget, "load_anonymous_cart", %{"cart_id" => anon_cart.id})

      assert cart_widget_html(view) =~ "dropdown dropdown-end"
    end

    test "cart widget uses the session's locale", %{conn: conn} do
      {:ok, anon_cart} = Commerce.create_cart()

      {:ok, view, _html} = live(conn, ~p"/?locale=de")
      widget = find_live_child(view, "cart-widget")
      render_hook(widget, "load_anonymous_cart", %{"cart_id" => anon_cart.id})

      html = cart_widget_html(view)
      assert html =~ "Warenkorb anzeigen"
      refute html =~ "View cart"
    end

    test "cart widget stays hidden for unknown cart id", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      widget = find_live_child(view, "cart-widget")
      render_hook(widget, "load_anonymous_cart", %{"cart_id" => Ash.UUID.generate()})

      refute cart_widget_html(view) =~ "dropdown dropdown-end"
    end

    test "cart widget updates item count on pubsub :cart_updated", %{conn: conn} do
      %{owner: owner} = UserHelpers.create_studio_owner()

      item = InventoryHelpers.create_item(owner)

      {:ok, anon_cart} = Commerce.create_cart()

      {:ok, view, _html} = live(conn, ~p"/")
      widget = find_live_child(view, "cart-widget")
      render_hook(widget, "load_anonymous_cart", %{"cart_id" => anon_cart.id})

      Commerce.add_to_cart!(anon_cart.id, item.id)
      Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{anon_cart.id}", :cart_updated)

      assert cart_widget_html(view) =~ "1"
    end
  end

  describe "authenticated user" do
    setup %{conn: conn} do
      user = UserHelpers.create_user(%{password: @password})
      authed_conn = UserHelpers.log_in_user(conn, user)
      %{user: user, conn: authed_conn}
    end

    test "market page loads without redirect", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "Loka"
    end

    test "cart widget shows when user has a cart", %{conn: conn, user: user} do
      {:ok, _cart} = Commerce.create_cart(actor: user)

      {:ok, view, _html} = live(conn, ~p"/")
      assert cart_widget_html(view) =~ "dropdown dropdown-end"
    end

    test "cart widget is hidden when user has no cart", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      refute cart_widget_html(view) =~ "dropdown dropdown-end"
    end

    test "cart widget updates item count on pubsub :cart_updated", %{conn: conn, user: user} do
      %{owner: owner} = UserHelpers.create_studio_owner()

      item = InventoryHelpers.create_item(owner)

      {:ok, cart} = Commerce.create_cart(actor: user)

      {:ok, view, _html} = live(conn, ~p"/")

      Commerce.add_to_cart!(cart.id, item.id)
      Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)

      assert cart_widget_html(view) =~ "1"
    end

    test "cart widget appears after cart is created via pubsub", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/")
      refute cart_widget_html(view) =~ "dropdown dropdown-end"

      {:ok, cart} = Commerce.create_cart(actor: user)

      Phoenix.PubSub.broadcast(
        Loka.PubSub,
        "user:#{user.id}:cart_created",
        {:cart_created, cart.id}
      )

      assert cart_widget_html(view) =~ "dropdown dropdown-end"
    end

    test "merges the anonymous cart from before signing in, once, and tells the browser to forget it",
         %{conn: conn, user: user} do
      %{owner: owner} = UserHelpers.create_studio_owner()
      item = InventoryHelpers.create_item(owner)
      {:ok, anon_cart} = Commerce.create_cart()
      Commerce.add_to_cart!(anon_cart.id, item.id)

      {:ok, view, _html} = live(conn, ~p"/")
      widget = find_live_child(view, "cart-widget")
      render_hook(widget, "load_anonymous_cart", %{"cart_id" => anon_cart.id})

      assert_reply(widget, %{forget: true})
      assert cart_widget_html(view) =~ "1"
      assert {:ok, nil} = Commerce.get_anonymous_cart(anon_cart.id)

      cart = Commerce.get_user_cart!(actor: user, load: :item_count)
      assert cart.item_count == 1
    end
  end
end

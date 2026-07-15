defmodule LokaWeb.Shop.CartWidgetLiveTest do
  use LokaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Loka.Commerce
  alias Loka.Support.UserHelpers

  @password "password123"

  defp cart_widget_html(view) do
    view |> find_live_child("cart-widget") |> render()
  end

  describe "anonymous user" do
    test "landing page loads without redirect", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "keraloka"
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

    test "cart widget stays hidden for unknown cart id", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      widget = find_live_child(view, "cart-widget")
      render_hook(widget, "load_anonymous_cart", %{"cart_id" => Ash.UUID.generate()})

      refute cart_widget_html(view) =~ "dropdown dropdown-end"
    end

    test "cart widget updates item count on pubsub :cart_updated", %{conn: conn} do
      %{owner: owner} = UserHelpers.create_studio_owner()

      stock =
        Loka.Inventory.create_stock!(
          %{name: "Widget", description: "A widget"},
          %{quantity: 10, price: Money.new(:CHF, 500)},
          actor: owner
        )

      {:ok, anon_cart} = Commerce.create_cart()

      {:ok, view, _html} = live(conn, ~p"/")
      widget = find_live_child(view, "cart-widget")
      render_hook(widget, "load_anonymous_cart", %{"cart_id" => anon_cart.id})

      Commerce.add_to_cart!(anon_cart.id, stock.id)
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

    test "landing page loads without redirect", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "keraloka"
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

      stock =
        Loka.Inventory.create_stock!(
          %{name: "Widget", description: "A widget"},
          %{quantity: 10, price: Money.new(:CHF, 500)},
          actor: owner
        )

      {:ok, cart} = Commerce.create_cart(actor: user)

      {:ok, view, _html} = live(conn, ~p"/")

      Commerce.add_to_cart!(cart.id, stock.id)
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

    test "ignores load_anonymous_cart event when user is authenticated", %{conn: conn, user: user} do
      {:ok, anon_cart} = Commerce.create_cart()
      {:ok, _user_cart} = Commerce.create_cart(actor: user)

      {:ok, view, _html} = live(conn, ~p"/")
      widget = find_live_child(view, "cart-widget")

      html_before = render(widget)
      render_hook(widget, "load_anonymous_cart", %{"cart_id" => anon_cart.id})

      assert render(widget) == html_before
    end
  end
end

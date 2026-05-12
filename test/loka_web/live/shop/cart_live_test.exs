defmodule LokaWeb.Shop.CartLiveTest do
  use LokaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Loka.Commerce
  alias Loka.Inventory
  alias Loka.Support.UserHelpers

  @password "password123"

  defp create_stock do
    %{owner: owner} = UserHelpers.create_studio_owner()

    Inventory.create_stock!(
      %{name: "Cup", description: "A nice cup"},
      %{quantity: 10, price: Money.new(:CHF, 1500)},
      actor: owner
    )
  end

  describe "anonymous user" do
    test "renders empty state without a cart", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/shop/cart")
      assert html =~ "Dein Warenkorb ist leer"
    end

    test "loads anonymous cart via hook event", %{conn: conn} do
      stock = create_stock()
      {:ok, cart} = Commerce.create_cart()
      Commerce.add_to_cart!(cart.id, stock.id)

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      render_hook(view, "load_anonymous_cart", %{"cart_id" => cart.id})

      assert render(view) =~ "Cup"
    end

    test "ignores unknown cart id", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      render_hook(view, "load_anonymous_cart", %{"cart_id" => Ash.UUID.generate()})

      assert render(view) =~ "Dein Warenkorb ist leer"
    end

    test "refreshes on :cart_updated pubsub", %{conn: conn} do
      stock = create_stock()
      {:ok, cart} = Commerce.create_cart()

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      render_hook(view, "load_anonymous_cart", %{"cart_id" => cart.id})

      refute render(view) =~ "Cup"

      Commerce.add_to_cart!(cart.id, stock.id)
      Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)

      assert render(view) =~ "Cup"
    end

    test "decrease_quantity removes item from anonymous cart", %{conn: conn} do
      stock = create_stock()
      {:ok, cart} = Commerce.create_cart()
      Commerce.add_to_cart!(cart.id, stock.id)

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      render_hook(view, "load_anonymous_cart", %{"cart_id" => cart.id})

      assert render(view) =~ "Cup"

      view |> element("button[phx-click='decrease_quantity']") |> render_click()
      Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)

      assert render(view) =~ "Dein Warenkorb ist leer"
    end
  end

  describe "authenticated user" do
    setup %{conn: conn} do
      user = UserHelpers.create_user(%{password: @password})
      authed_conn = UserHelpers.log_in_user(conn, user)
      %{user: user, conn: authed_conn}
    end

    test "renders empty state when user has no cart", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/shop/cart")
      assert html =~ "Dein Warenkorb ist leer"
    end

    test "renders cart items when user has a cart", %{conn: conn, user: user} do
      stock = create_stock()
      {:ok, cart} = Commerce.create_cart(actor: user)
      Commerce.add_to_cart!(cart.id, stock.id)

      {:ok, _view, html} = live(conn, ~p"/shop/cart")
      assert html =~ "Cup"
    end

    test "increase_quantity adds another unit", %{conn: conn, user: user} do
      stock = create_stock()
      {:ok, cart} = Commerce.create_cart(actor: user)
      Commerce.add_to_cart!(cart.id, stock.id)

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      view |> element("button[phx-click='increase_quantity']") |> render_click()
      Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)

      assert render(view) =~ "2"
    end

    test "decrease_quantity removes item when quantity is 1", %{conn: conn, user: user} do
      stock = create_stock()
      {:ok, cart} = Commerce.create_cart(actor: user)
      Commerce.add_to_cart!(cart.id, stock.id)

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      view |> element("button[phx-click='decrease_quantity']") |> render_click()
      Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)

      assert render(view) =~ "Dein Warenkorb ist leer"
    end

    test "ignores load_anonymous_cart when authenticated", %{conn: conn, user: user} do
      stock = create_stock()
      {:ok, anon_cart} = Commerce.create_cart()
      Commerce.add_to_cart!(anon_cart.id, stock.id)

      {:ok, cart} = Commerce.create_cart(actor: user)
      _ = cart

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      html_before = render(view)

      render_hook(view, "load_anonymous_cart", %{"cart_id" => anon_cart.id})

      assert render(view) == html_before
    end

    test "refreshes on :cart_updated pubsub", %{conn: conn, user: user} do
      stock = create_stock()
      {:ok, cart} = Commerce.create_cart(actor: user)

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      refute render(view) =~ "Cup"

      Commerce.add_to_cart!(cart.id, stock.id)
      Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)

      assert render(view) =~ "Cup"
    end
  end
end

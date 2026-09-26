defmodule LokaWeb.Shop.CartLiveTest do
  use LokaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Loka.Commerce
  alias Loka.Inventory
  alias Loka.Support.{InventoryHelpers, UserHelpers}

  @password "password123"

  defp create_item do
    %{owner: owner} = UserHelpers.create_studio_owner()

    InventoryHelpers.create_item(owner, %{
      name: "Cup",
      description: "A nice cup",
      stock: %{quantity: 10, price: Money.new(:CHF, 1500)}
    })
  end

  describe "anonymous user" do
    test "renders empty state without a cart", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/shop/cart")
      assert html =~ "Dein Warenkorb ist leer"
    end

    test "loads anonymous cart via hook event", %{conn: conn} do
      item = create_item()
      {:ok, cart} = Commerce.create_cart()
      Commerce.add_to_cart!(cart.id, item.id)

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
      item = create_item()
      {:ok, cart} = Commerce.create_cart()

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      render_hook(view, "load_anonymous_cart", %{"cart_id" => cart.id})

      refute render(view) =~ "Cup"

      Commerce.add_to_cart!(cart.id, item.id)
      Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)

      assert render(view) =~ "Cup"
    end

    test "item taken off sale stays in the cart as unavailable", %{conn: conn} do
      %{owner: owner} = UserHelpers.create_studio_owner()
      item = InventoryHelpers.create_item(owner)
      {:ok, cart} = Commerce.create_cart()
      Commerce.add_to_cart!(cart.id, item.id)
      :ok = Inventory.archive_stock(item.stock, actor: owner)

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      render_hook(view, "load_anonymous_cart", %{"cart_id" => cart.id})

      assert has_element?(view, "p", "Nicht mehr online erhältlich")
      assert has_element?(view, "button[phx-click='increase_quantity'][disabled]")
    end

    test "decrease_quantity removes item from anonymous cart", %{conn: conn} do
      item = create_item()
      {:ok, cart} = Commerce.create_cart()
      Commerce.add_to_cart!(cart.id, item.id)

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
      item = create_item()
      {:ok, cart} = Commerce.create_cart(actor: user)
      Commerce.add_to_cart!(cart.id, item.id)

      {:ok, _view, html} = live(conn, ~p"/shop/cart")
      assert html =~ "Cup"
    end

    test "increase_quantity adds another unit", %{conn: conn, user: user} do
      item = create_item()
      {:ok, cart} = Commerce.create_cart(actor: user)
      Commerce.add_to_cart!(cart.id, item.id)

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      view |> element("button[phx-click='increase_quantity']") |> render_click()
      Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)

      assert render(view) =~ "2"
    end

    test "decrease_quantity removes item when quantity is 1", %{conn: conn, user: user} do
      item = create_item()
      {:ok, cart} = Commerce.create_cart(actor: user)
      Commerce.add_to_cart!(cart.id, item.id)

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      view |> element("button[phx-click='decrease_quantity']") |> render_click()
      Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)

      assert render(view) =~ "Dein Warenkorb ist leer"
    end

    test "ignores load_anonymous_cart when authenticated", %{conn: conn, user: user} do
      item = create_item()
      {:ok, anon_cart} = Commerce.create_cart()
      Commerce.add_to_cart!(anon_cart.id, item.id)

      {:ok, cart} = Commerce.create_cart(actor: user)
      _ = cart

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      html_before = render(view)

      render_hook(view, "load_anonymous_cart", %{"cart_id" => anon_cart.id})

      assert render(view) == html_before
    end

    test "refreshes on :cart_updated pubsub", %{conn: conn, user: user} do
      item = create_item()
      {:ok, cart} = Commerce.create_cart(actor: user)

      {:ok, view, _html} = live(conn, ~p"/shop/cart")
      refute render(view) =~ "Cup"

      Commerce.add_to_cart!(cart.id, item.id)
      Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)

      assert render(view) =~ "Cup"
    end
  end
end

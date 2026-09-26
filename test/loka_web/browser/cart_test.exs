defmodule LokaWeb.Browser.CartTest do
  @moduledoc """
  Browser tests for the cart's JS hooks (add to cart, cart widget), which
  LiveViewTest can't run.
  """

  use PhoenixTest.Playwright.Case, async: true

  # Skip with `mix test --exclude playwright`
  @moduletag :playwright
  use LokaWeb, :verified_routes

  alias Loka.Commerce
  alias Loka.Support.{InventoryHelpers, UserHelpers}

  @password "password123"

  setup do
    %{owner: owner} = UserHelpers.create_studio_owner()
    %{item: InventoryHelpers.create_item(owner, %{name: "Becher Seladon"})}
  end

  defp add_to_cart(conn, item) do
    click_button(conn, "#add-to-cart-#{item.id} button", "In den Warenkorb")
  end

  defp remembered_cart_id(conn, fun) do
    evaluate(conn, ~s|localStorage.getItem("cart-id")|, fun)
  end

  defp connected(conn), do: assert_has(conn, "[data-phx-main].phx-connected")

  # Waits for the redirect back to the market to finish
  defp sign_in(conn, user) do
    conn
    |> visit(~p"/sign-in")
    # Input typed before the LiveView connects is lost when it re-renders
    |> connected()
    |> within("#user-password-sign-in-with-password", fn session ->
      session
      |> fill_in("Email", with: to_string(user.email))
      |> fill_in("Password", with: @password)
      |> click_button("Sign in")
    end)
    |> assert_has("[role='alert']", text: "You are now signed in")
  end

  test "anonymous visitor: cart is created on the first click and kept across reloads",
       %{conn: conn, item: item} do
    conn
    |> visit(~p"/")
    |> connected()
    |> refute_has("#cart-widget .badge")
    |> add_to_cart(item)
    |> assert_has("#cart-widget .badge", text: "1")
    |> remembered_cart_id(fn cart_id ->
      assert {:ok, %{id: ^cart_id}} = Commerce.get_anonymous_cart(cart_id)
    end)
    |> reload_page()
    |> assert_has("#cart-widget .badge", text: "1")
    |> add_to_cart(item)
    |> assert_has("#cart-widget .badge", text: "2")
  end

  test "signing in merges the anonymous cart and the browser forgets its id",
       %{conn: conn, item: item} do
    user = UserHelpers.create_user(%{password: @password})

    conn
    |> visit(~p"/")
    |> connected()
    |> add_to_cart(item)
    |> assert_has("#cart-widget .badge", text: "1")
    |> sign_in(user)
    |> assert_has("#cart-widget .badge", text: "1")
    |> remembered_cart_id(&assert(&1 == nil))

    assert %{item_count: 1} = Commerce.get_user_cart!(actor: user, load: :item_count)
  end

  test "viewing the market doesn't touch any cart", %{conn: conn} do
    user = UserHelpers.create_user(%{password: @password})

    conn
    |> sign_in(user)
    |> connected()
    # Give mount-time hook events time to reach the server; there's no
    # positive signal to wait for when the point is that nothing happens
    |> evaluate("new Promise(resolve => setTimeout(resolve, 500))")

    # Before, every add-to-cart button asked for a cart on mount, which
    # created one for a signed-in user just by looking at the market
    assert {:ok, nil} = Commerce.get_user_cart(actor: user)
  end
end

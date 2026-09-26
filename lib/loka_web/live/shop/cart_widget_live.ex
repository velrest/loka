defmodule LokaWeb.Shop.CartWidgetLive do
  alias Loka.Commerce
  use LokaWeb, :live_view

  # Nested via live_render, so the router's live_session hooks don't run here
  on_mount LokaWeb.LiveLocale
  on_mount {LokaWeb.LiveUserAuth, :current_user}

  @impl true
  def render(assigns) do
    ~H"""
    <div id="cart-widget-root" phx-hook=".CartWidget" class="contents">
      <div
        :if={@cart}
        class="dropdown dropdown-end shrink-0"
      >
        <div tabindex="0" role="button" class="btn btn-secondary gap-2">
          <.icon name="hero-shopping-cart" />
          {gettext("Warenkorb")}
          <span :if={@cart.item_count > 0} class="badge badge-primary badge-soft badge-sm">
            {@cart.item_count}
          </span>
        </div>
        <div
          tabindex="0"
          class="card card-compact dropdown-content bg-base-100 border border-base-300 z-1 mt-3 w-60 shadow shadow-black/30"
        >
          <div class="card-body">
            <span class="text-lg font-bold">
              {@cart.item_count} {ngettext("Produkt", "Produkte", @cart.item_count)}
            </span>
            <span :if={@cart.subtotal} class="text-secondary">
              {gettext("Zwischensumme")}: {@cart.subtotal}
            </span>
            <div class="card-actions">
              <.link navigate={~p"/shop/cart"} class="btn btn-primary btn-block whitespace-nowrap">
                {gettext("Warenkorb anzeigen")}
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".CartWidget">
      export default {
        mounted() {
          // The widget is on every page exactly once, so it's the one place
          // that syncs the browser's anonymous cart with the server
          const load = (cart_id) =>
            this.pushEvent("load_anonymous_cart", {cart_id}, ({forget}) => {
              if (forget) localStorage.removeItem("cart-id")
            })

          const cartId = localStorage.getItem("cart-id")
          if (cartId) load(cartId)

          this._onCartCreated = ({detail: {cart_id}}) => load(cart_id)
          window.addEventListener("cart-created", this._onCartCreated)
        },
        destroyed() {
          window.removeEventListener("cart-created", this._onCartCreated)
        }
      }
    </script>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    if user do
      {:ok, cart} = Commerce.get_user_cart(load: [:item_count, :subtotal], actor: user)

      if connected?(socket), do: subscribe_to_cart(cart, user)

      {:ok, assign(socket, cart: cart)}
    else
      {:ok, assign(socket, cart: nil)}
    end
  end

  # Signed in: the anonymous cart from before signing in is merged into the
  # user's cart, and the browser can forget its id
  @impl true
  def handle_event(
        "load_anonymous_cart",
        %{"cart_id" => cart_id},
        %{assigns: %{current_user: user}} = socket
      )
      when not is_nil(user) do
    {:ok, cart} = Commerce.ensure_cart_for_session(%{anonymous_cart_id: cart_id}, actor: user)
    Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)

    cart = Commerce.get_user_cart!(load: [:item_count, :subtotal], actor: user)
    {:reply, %{forget: true}, show_cart(socket, cart)}
  end

  def handle_event("load_anonymous_cart", %{"cart_id" => cart_id}, socket) do
    case Commerce.get_anonymous_cart(cart_id, load: [:item_count, :subtotal]) do
      # Unknown or cleaned-up cart: the next add to cart starts a new one
      {:ok, nil} -> {:reply, %{forget: true}, socket}
      {:ok, cart} -> {:reply, %{forget: false}, show_cart(socket, cart)}
    end
  end

  @impl true
  def handle_info({:cart_created, _cart_id}, socket) do
    user = socket.assigns.current_user
    cart = Commerce.get_user_cart!(load: [:item_count, :subtotal], actor: user)
    {:noreply, show_cart(socket, cart)}
  end

  def handle_info(:cart_updated, socket) do
    cart = socket.assigns.cart
    user = socket.assigns.current_user

    updated_cart =
      if user do
        Commerce.get_user_cart!(load: [:item_count, :subtotal], actor: user)
      else
        Commerce.get_anonymous_cart!(cart.id, load: [:item_count, :subtotal])
      end

    {:noreply, assign(socket, cart: updated_cart)}
  end

  # Subscribes to the cart's updates, once per cart
  defp show_cart(socket, cart) do
    current = socket.assigns.cart

    if connected?(socket) and (is_nil(current) or current.id != cart.id) do
      if current, do: Phoenix.PubSub.unsubscribe(Loka.PubSub, "cart:#{current.id}")

      if user = socket.assigns.current_user do
        Phoenix.PubSub.unsubscribe(Loka.PubSub, "user:#{user.id}:cart_created")
      end

      Phoenix.PubSub.subscribe(Loka.PubSub, "cart:#{cart.id}")
    end

    assign(socket, cart: cart)
  end

  defp subscribe_to_cart(nil, user),
    do: Phoenix.PubSub.subscribe(Loka.PubSub, "user:#{user.id}:cart_created")

  defp subscribe_to_cart(cart, _user),
    do: Phoenix.PubSub.subscribe(Loka.PubSub, "cart:#{cart.id}")
end

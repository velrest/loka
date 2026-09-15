defmodule LokaWeb.Shop.CartWidgetLive do
  alias Loka.Commerce
  use LokaWeb, :live_view

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
          {gettext("Warenkorb")}
          <span
            :if={@cart.item_count > 0}
            class="inline-flex items-center bg-primary/15 text-primary px-2 py-0.5 rounded-md text-[11px]"
          >
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
          const cartId = localStorage.getItem("cart-id")
          if (cartId) {
            this.pushEvent("load_anonymous_cart", {cart_id: cartId})
          }
          window.addEventListener("cart-created", ({detail: {cart_id}}) => {
            this.pushEvent("load_anonymous_cart", {cart_id})
          })
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

      if connected?(socket) do
        if cart do
          Phoenix.PubSub.subscribe(Loka.PubSub, "cart:#{cart.id}")
        else
          Phoenix.PubSub.subscribe(Loka.PubSub, "user:#{user.id}:cart_created")
        end
      end

      {:ok, assign(socket, cart: cart)}
    else
      {:ok, assign(socket, cart: nil)}
    end
  end

  @impl true
  def handle_event("load_anonymous_cart", _params, %{assigns: %{current_user: user}} = socket)
      when not is_nil(user) do
    {:noreply, socket}
  end

  def handle_event("load_anonymous_cart", %{"cart_id" => cart_id}, socket) do
    case Commerce.get_anonymous_cart(cart_id, load: [:item_count, :subtotal]) do
      {:ok, nil} ->
        {:noreply, socket}

      {:ok, cart} ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(Loka.PubSub, "cart:#{cart.id}")
        end

        {:noreply, assign(socket, cart: cart)}
    end
  end

  @impl true
  def handle_info({:cart_created, cart_id}, socket) do
    user = socket.assigns.current_user
    cart = Commerce.get_user_cart!(load: [:item_count, :subtotal], actor: user)

    if connected?(socket) do
      Phoenix.PubSub.unsubscribe(Loka.PubSub, "user:#{user.id}:cart_created")
      Phoenix.PubSub.subscribe(Loka.PubSub, "cart:#{cart_id}")
    end

    {:noreply, assign(socket, cart: cart)}
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
end

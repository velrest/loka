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
        class="dropdown dropdown-end"
      >
        <div tabindex="0" role="button" class="btn btn-ghost btn-circle">
          <div class="indicator">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"
              />
            </svg>
            <span :if={@cart.item_count > 0} class="badge badge-sm indicator-item">
              {@cart.item_count}
            </span>
          </div>
        </div>
        <div
          tabindex="0"
          class="card card-compact dropdown-content bg-base-100 z-1 mt-3 w-52 shadow"
        >
          <div class="card-body">
            <span class="text-lg font-bold">
              {@cart.item_count} {ngettext("Produkt", "Produkte", @cart.item_count)}
            </span>
            <span :if={@cart.subtotal} class="text-info">Subtotal: {@cart.subtotal}</span>
            <div class="card-actions">
              <button class="btn btn-primary btn-block">View cart</button>
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
    case Commerce.get_anonymous_cart(cart_id) do
      {:ok, nil} ->
        {:noreply, socket}

      {:ok, cart} ->
        cart = Ash.load!(cart, [:item_count, :subtotal], authorize?: false)

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
        Ash.load!(cart, [:item_count, :subtotal], authorize?: false)
      end

    {:noreply, assign(socket, cart: updated_cart)}
  end
end

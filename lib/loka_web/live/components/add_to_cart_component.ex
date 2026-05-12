defmodule LokaWeb.AddToCartComponent do
  alias Loka.Commerce
  use LokaWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
     assign(socket,
       stock: assigns.stock,
       current_user: assigns[:current_user],
       cart_id: socket.assigns[:cart_id]
     )}
  end

  attr :stock, Loka.Inventory.Stock, required: true
  attr :current_user, :any, default: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={"add-to-cart-#{@stock.id}"}
      phx-hook=".AddToCart"
      class="contents"
    >
      <button
        class="btn btn-primary"
        phx-click="add_to_cart"
        phx-value-stock_id={@stock.id}
        phx-target={@myself}
      >
        {gettext("In den Warenkorb")}
      </button>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".AddToCart">
      export default {
        mounted() {
          const cartId = localStorage.getItem("cart-id")
          this.pushEventTo(this.el, "ensure_cart", {cart_id: cartId || ""})
          this.handleEvent("cart_assigned", ({cart_id, anonymous}) => {
            if (anonymous && cart_id) {
              const isNew = localStorage.getItem("cart-id") !== cart_id
              localStorage.setItem("cart-id", cart_id)
              if (isNew) {
                window.dispatchEvent(new CustomEvent("cart-created", {detail: {cart_id}}))
              }
            } else {
              localStorage.removeItem("cart-id")
            }
          })
          this._cartCreatedHandler = ({detail: {cart_id}}) => {
            if (this.el.isConnected) {
              this.pushEventTo(this.el, "ensure_cart", {cart_id})
            }
          }
          window.addEventListener("cart-created", this._cartCreatedHandler)
        },
        destroyed() {
          window.removeEventListener("cart-created", this._cartCreatedHandler)
        }
      }
    </script>
    </div>
    """
  end

  @impl true
  def handle_event("ensure_cart", %{"cart_id" => cart_id}, socket) do
    anonymous_cart_id = if cart_id == "", do: nil, else: cart_id

    if is_nil(anonymous_cart_id) and is_nil(socket.assigns.current_user) do
      # No existing cart and no user — defer creation to the first add_to_cart click
      {:noreply, socket}
    else
      params = if anonymous_cart_id, do: %{anonymous_cart_id: anonymous_cart_id}, else: %{}
      {:ok, cart} = Commerce.ensure_cart_for_session(params, actor: socket.assigns.current_user)

      if cart.user_id do
        Phoenix.PubSub.broadcast(
          Loka.PubSub,
          "user:#{cart.user_id}:cart_created",
          {:cart_created, cart.id}
        )
      end

      socket =
        socket
        |> assign(cart_id: cart.id)
        |> push_event("cart_assigned", %{cart_id: cart.id, anonymous: is_nil(cart.user_id)})

      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("add_to_cart", %{"stock_id" => stock_id}, socket) do
    {cart_id, socket} =
      case socket.assigns[:cart_id] do
        nil ->
          {:ok, cart} = Commerce.ensure_cart_for_session(%{}, actor: socket.assigns.current_user)

          if cart.user_id do
            Phoenix.PubSub.broadcast(
              Loka.PubSub,
              "user:#{cart.user_id}:cart_created",
              {:cart_created, cart.id}
            )
          end

          socket =
            socket
            |> assign(cart_id: cart.id)
            |> push_event("cart_assigned", %{cart_id: cart.id, anonymous: is_nil(cart.user_id)})

          {cart.id, socket}

        cart_id ->
          {cart_id, socket}
      end

    Commerce.add_to_cart!(cart_id, stock_id)
    Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart_id}", :cart_updated)

    {:noreply, socket}
  end
end

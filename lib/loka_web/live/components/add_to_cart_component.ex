defmodule LokaWeb.AddToCartComponent do
  @moduledoc """
  "Add to cart" button for an item. Only render it for items in stock.

  Nothing happens until it's clicked: the click sends the anonymous cart id
  from the browser (if any), the server finds or creates the cart, and replies
  with the cart id so an anonymous visitor's browser can remember it. Merging
  an anonymous cart after signing in is done once per page by
  `LokaWeb.Shop.CartWidgetLive`, not here.
  """

  alias Loka.Commerce
  use LokaWeb, :live_component

  attr :item, Loka.Inventory.Item, required: true
  attr :current_user, :any, default: nil
  attr :class, :any, default: "btn-primary"

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={"add-to-cart-#{@item.id}"}
      phx-hook=".AddToCart"
      data-item-id={@item.id}
      phx-target={@myself}
      class="contents"
    >
      <button type="button" class={["btn", @class]}>
        {gettext("In den Warenkorb")}
      </button>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".AddToCart">
        export default {
          mounted() {
            this.el.querySelector("button").addEventListener("click", () => {
              const payload = {
                item_id: this.el.dataset.itemId,
                cart_id: localStorage.getItem("cart-id") || ""
              }

              // The reply only reaches this button, not every button on the page
              this.pushEventTo(this.el, "add_to_cart", payload, ({cart_id, anonymous}) => {
                if (!anonymous) {
                  localStorage.removeItem("cart-id")
                } else if (localStorage.getItem("cart-id") !== cart_id) {
                  localStorage.setItem("cart-id", cart_id)
                  window.dispatchEvent(new CustomEvent("cart-created", {detail: {cart_id}}))
                }
              })
            })
          }
        }
      </script>
    </div>
    """
  end

  @impl true
  def handle_event("add_to_cart", %{"item_id" => item_id} = params, socket) do
    user = socket.assigns.current_user

    session_params =
      case params["cart_id"] do
        id when id in [nil, ""] -> %{}
        id -> %{anonymous_cart_id: id}
      end

    {:ok, cart} = Commerce.ensure_cart_for_session(session_params, actor: user)
    Commerce.add_to_cart!(cart.id, item_id)

    # A signed-in user's widget may not know this cart yet
    if cart.user_id do
      Phoenix.PubSub.broadcast(
        Loka.PubSub,
        "user:#{cart.user_id}:cart_created",
        {:cart_created, cart.id}
      )
    end

    Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)

    {:reply, %{cart_id: cart.id, anonymous: is_nil(cart.user_id)}, socket}
  end
end

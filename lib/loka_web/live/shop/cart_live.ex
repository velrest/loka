defmodule LokaWeb.Shop.CartLive do
  alias Loka.Commerce
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @cart_load [
    :subtotal,
    :item_count,
    cart_items: [item: [:studio, :images, :stock, :in_stock?]]
  ]

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    cart =
      if user do
        Commerce.get_user_cart!(load: @cart_load, actor: user)
      else
        nil
      end

    if cart && connected?(socket) do
      Phoenix.PubSub.subscribe(Loka.PubSub, "cart:#{cart.id}")
    end

    {:ok, assign(socket, cart: cart)}
  end

  @impl true
  def handle_event("load_anonymous_cart", _, %{assigns: %{current_user: user}} = socket)
      when not is_nil(user),
      do: {:noreply, socket}

  def handle_event("load_anonymous_cart", %{"cart_id" => cart_id}, socket) do
    case Commerce.get_anonymous_cart(cart_id, load: @cart_load) do
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
  def handle_event("increase_quantity", %{"item_id" => item_id}, socket) do
    cart = socket.assigns.cart
    Commerce.add_to_cart!(cart.id, item_id)
    Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)
    {:noreply, socket}
  end

  def handle_event("decrease_quantity", %{"item_id" => item_id}, socket) do
    cart = socket.assigns.cart
    user = socket.assigns.current_user

    cart.cart_items
    |> Enum.find(&(&1.item_id == item_id))
    |> case do
      nil -> :ok
      cart_item -> Commerce.remove_from_cart!(cart_item, actor: user)
    end

    Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)
    {:noreply, socket}
  end

  @impl true
  def handle_info(:cart_updated, socket) do
    user = socket.assigns.current_user
    cart = socket.assigns.cart

    updated_cart =
      if user do
        Commerce.get_user_cart!(load: @cart_load, actor: user)
      else
        Commerce.get_anonymous_cart!(cart.id, load: @cart_load)
      end

    {:noreply, assign(socket, cart: updated_cart)}
  end

  @impl true
  def render(assigns) do
    line_items = cart_line_items(assigns.cart)
    assigns = assign(assigns, line_items: line_items, shipping_note: shipping_note(line_items))

    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket} locale={@locale}>
      <div id="cart-page" phx-hook=".CartPage">
        <.back_link navigate={~p"/"}>{gettext("Zurück zum Markt")}</.back_link>

        <h1 class="page-title mt-3.5 mb-6">
          {gettext("Warenkorb")}
          <span
            :if={@cart && @cart.item_count > 0}
            class="text-lg font-normal text-secondary tracking-normal ml-2"
          >
            {@cart.item_count} {ngettext("Artikel", "Artikel", @cart.item_count)}
          </span>
        </h1>

        <%!-- Empty state --%>
        <.empty_state :if={@line_items == []} message={gettext("Dein Warenkorb ist leer.")}>
          <:icon>
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="size-12 mx-auto mb-4 opacity-30"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="1"
                d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"
              />
            </svg>
          </:icon>
          <:action>
            <.link navigate={~p"/"} class="btn btn-primary btn-sm">
              {gettext("Zum Shop")}
            </.link>
          </:action>
        </.empty_state>

        <%!-- Cart content --%>
        <div
          :if={@line_items != []}
          class="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_380px] gap-8 items-start pb-16"
        >
          <div>
            <div
              :for={{item, quantity} <- @line_items}
              class="flex items-center gap-4.5 py-4.5 rule-fade-bottom"
            >
              <%!-- Thumbnail --%>
              <.item_thumbnail
                images={item.images}
                alt={item.name}
                class="shrink-0 size-20 rounded-field bg-base-300"
              />

              <%!-- Info --%>
              <div class="flex-1 min-w-0">
                <.link
                  navigate={~p"/shop/item/#{item.id}"}
                  class="text-lg tracking-tight hover:text-primary transition-colors duration-150"
                >
                  {item.name}
                </.link>
                <.link
                  navigate={~p"/shop/studio/#{item.studio.id}"}
                  class="block studio-link"
                >
                  {item.studio.name} · {item.studio.city}
                </.link>
                <p :if={item.stock} class="text-xs text-secondary mt-0.5">
                  {item.stock.price} {gettext("/ Stück")}
                </p>
                <p :if={!item.stock} class="text-xs text-error mt-0.5">
                  {gettext("Nicht mehr online erhältlich")}
                </p>
              </div>

              <%!-- Qty stepper --%>
              <div class="join shrink-0">
                <button
                  phx-click="decrease_quantity"
                  phx-value-item_id={item.id}
                  class="join-item px-3 border border-base-300 hover:bg-base-content/7 transition-colors duration-150"
                >
                  <%= if quantity == 1 do %>
                    <.icon name="hero-trash" class="size-4 text-error" />
                  <% else %>
                    −
                  <% end %>
                </button>
                <span class="join-item grid place-items-center w-9 text-sm tabular-nums border border-base-300">
                  {quantity}
                </span>
                <button
                  phx-click="increase_quantity"
                  phx-value-item_id={item.id}
                  disabled={!item.in_stock?}
                  class="join-item px-3 border border-base-300 hover:bg-base-content/7 transition-colors duration-150 disabled:opacity-40"
                >
                  +
                </button>
              </div>

              <span class="w-32 text-right text-base whitespace-nowrap">
                {line_total(item, quantity)}
              </span>
            </div>

            <p :if={@shipping_note} class="text-xs text-secondary mt-4.5">
              {@shipping_note}
            </p>
          </div>

          <%!-- Summary --%>
          <div class="flex flex-col gap-3 p-5 rounded-field bg-base-100 card-hairline">
            <h4 class="text-lg m-0">{gettext("Zusammenfassung")}</h4>

            <div class="flex justify-between text-sm">
              <span class="text-secondary">{gettext("Zwischensumme")}</span>
              <span>{@cart.subtotal}</span>
            </div>

            <div class="flex justify-between text-sm">
              <span class="text-secondary">{gettext("Versand")}</span>
              <span class="text-secondary">{gettext("wird berechnet")}</span>
            </div>

            <div class="h-px bg-base-300 my-1"></div>

            <div class="flex justify-between text-lg">
              <span>{gettext("Gesamt")}</span>
              <span>{@cart.subtotal}</span>
            </div>

            <.button class="btn btn-primary btn-block" disabled>
              {gettext("Zur Kasse")}
            </.button>
            <div class="text-center text-xs text-secondary">
              {gettext("TWINT · Visa · Mastercard — CHF")}
            </div>
          </div>
        </div>
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".CartPage">
        export default {
          mounted() {
            const cartId = localStorage.getItem("cart-id")
            if (cartId) {
              this.pushEvent("load_anonymous_cart", {cart_id: cartId})
            }
          }
        }
      </script>
    </Layouts.app>
    """
  end

  defp cart_line_items(nil), do: []

  defp cart_line_items(%{cart_items: cart_items}) do
    cart_items
    |> Enum.group_by(& &1.item_id)
    |> Enum.map(fn {_item_id, [first | _] = entries} -> {first.item, length(entries)} end)
  end

  defp line_total(%{stock: %{price: price}}, quantity), do: Money.mult!(price, quantity)
  defp line_total(_item, _quantity), do: nil

  defp shipping_note(line_items) do
    studio_count =
      line_items
      |> Enum.map(fn {item, _quantity} -> item.studio_id end)
      |> Enum.uniq()
      |> length()

    if studio_count > 1 do
      gettext("Versand pro Studio getrennt")
    end
  end
end

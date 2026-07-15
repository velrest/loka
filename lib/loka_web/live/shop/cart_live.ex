defmodule LokaWeb.Shop.CartLive do
  alias Loka.Commerce
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @cart_load [:subtotal, :item_count, cart_stocks: [stock: [:studio, item: :images]]]

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
  def handle_event("increase_quantity", %{"stock_id" => stock_id}, socket) do
    cart = socket.assigns.cart
    Commerce.add_to_cart!(cart.id, stock_id)
    Phoenix.PubSub.broadcast(Loka.PubSub, "cart:#{cart.id}", :cart_updated)
    {:noreply, socket}
  end

  def handle_event("decrease_quantity", %{"stock_id" => stock_id}, socket) do
    cart = socket.assigns.cart
    user = socket.assigns.current_user

    cart.cart_stocks
    |> Enum.find(&(&1.stock_id == stock_id))
    |> case do
      nil -> :ok
      cart_stock -> Commerce.remove_from_cart!(cart_stock, actor: user)
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
    assigns = assign(assigns, :line_items, cart_line_items(assigns.cart))

    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket}>
      <div id="cart-page" phx-hook=".CartPage" class="px-4 py-10 sm:px-6 lg:px-8">
        <%!-- Header --%>
        <div class="mb-8">
          <.link
            navigate={~p"/"}
            class="text-sm text-base-content/50 hover:text-base-content transition-colors"
          >
            ← {gettext("Zurück zum Shop")}
          </.link>
          <h1 class="text-2xl font-bold mt-3">
            {gettext("Warenkorb")}
            <span
              :if={@cart && @cart.item_count > 0}
              class="text-base font-normal text-base-content/50 ml-2"
            >
              ({@cart.item_count} {ngettext("Artikel", "Artikel", @cart.item_count)})
            </span>
          </h1>
        </div>

        <%!-- Empty state --%>
        <div :if={@line_items == []} class="text-center py-24 text-base-content/40">
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
          <p class="text-lg mb-4">{gettext("Dein Warenkorb ist leer.")}</p>
          <.link navigate={~p"/"} class="btn btn-primary btn-sm">
            {gettext("Zum Shop")}
          </.link>
        </div>

        <%!-- Cart content --%>
        <div :if={@line_items != []} class="grid grid-cols-1 lg:grid-cols-3 gap-8 items-start">
          <%!-- Items --%>
          <div class="lg:col-span-2 card bg-base-100 border border-base-300 shadow shadow-black/30">
            <div class="card-body p-0 gap-0">
              <div
                :for={{stock, quantity, entries} <- @line_items}
                class="flex items-center gap-4 p-4 border-b border-base-200 last:border-0"
              >
                <%!-- Thumbnail --%>
                <div class="shrink-0 size-20 rounded-lg overflow-hidden bg-base-200">
                  <%= if stock.item.images != [] do %>
                    <img
                      src={List.first(stock.item.images).path}
                      alt={stock.item.name}
                      class="w-full h-full object-cover"
                    />
                  <% else %>
                    <img src="/images/placeholder-pot.svg" alt="" class="w-full h-full object-cover" />
                  <% end %>
                </div>

                <%!-- Info --%>
                <div class="flex-1 min-w-0">
                  <p class="text-xs font-medium text-primary uppercase tracking-widest opacity-70">
                    {stock.studio.name}
                  </p>
                  <.link
                    navigate={~p"/shop/item/#{stock.item.id}"}
                    class="font-semibold hover:text-primary transition-colors"
                  >
                    {stock.item.name}
                  </.link>
                  <p class="text-sm text-base-content/50 mt-0.5">
                    {stock.price} {gettext("/ Stück")}
                  </p>
                </div>

                <%!-- Qty & line total --%>
                <div class="flex flex-col items-end gap-3 shrink-0">
                  <span class="font-semibold">{line_total(entries)}</span>
                  <div class="flex items-center gap-1">
                    <button
                      phx-click="decrease_quantity"
                      phx-value-stock_id={stock.id}
                      class="btn btn-ghost btn-xs btn-square"
                    >
                      <%= if quantity == 1 do %>
                        <.icon name="hero-trash" class="size-4 text-error" />
                      <% else %>
                        −
                      <% end %>
                    </button>
                    <span class="w-7 text-center text-sm font-medium tabular-nums">{quantity}</span>
                    <button
                      phx-click="increase_quantity"
                      phx-value-stock_id={stock.id}
                      class="btn btn-ghost btn-xs btn-square"
                    >
                      +
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <%!-- Summary --%>
          <div class="card bg-base-100 border border-base-300 shadow shadow-black/30">
            <div class="card-body gap-4">
              <h3 class="font-semibold">{gettext("Zusammenfassung")}</h3>

              <div class="flex justify-between text-sm">
                <span class="text-base-content/50">{gettext("Zwischensumme")}</span>
                <span>{@cart.subtotal}</span>
              </div>

              <div class="flex justify-between text-sm">
                <span class="text-base-content/50">{gettext("Versand")}</span>
                <span class="text-base-content/40">{gettext("wird berechnet")}</span>
              </div>

              <div class="border-t border-base-200 pt-3 flex justify-between font-bold">
                <span>{gettext("Gesamt")}</span>
                <span>{@cart.subtotal}</span>
              </div>

              <.button class="btn btn-primary btn-block mt-2" disabled>
                {gettext("Zur Kasse")}
              </.button>
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
  defp cart_line_items(%{cart_stocks: []}), do: []

  defp cart_line_items(%{cart_stocks: cart_stocks}) do
    cart_stocks
    |> Enum.group_by(& &1.stock_id)
    |> Enum.map(fn {_stock_id, [first | _] = entries} ->
      {first.stock, length(entries), entries}
    end)
  end

  defp line_total(entries) do
    entries
    |> Enum.map(& &1.stock.price)
    |> Money.sum!()
  end
end

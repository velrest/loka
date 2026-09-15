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
    line_items = cart_line_items(assigns.cart)
    assigns = assign(assigns, line_items: line_items, shipping_note: shipping_note(line_items))

    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket}>
      <div id="cart-page" phx-hook=".CartPage">
        <.link
          navigate={~p"/"}
          class="text-[13px] text-secondary hover:text-base-content transition-colors duration-150"
        >
          ← {gettext("Zurück zum Markt")}
        </.link>

        <h1 class="text-[36px] sm:text-[44px] leading-[1.05] tracking-[-0.03em] font-medium mt-3.5 mb-6">
          {gettext("Warenkorb")}
          <span
            :if={@cart && @cart.item_count > 0}
            class="text-lg font-normal text-secondary tracking-normal ml-2"
          >
            {@cart.item_count} {ngettext("Artikel", "Artikel", @cart.item_count)}
          </span>
        </h1>

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
        <div
          :if={@line_items != []}
          class="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_380px] gap-8 items-start pb-16"
        >
          <div>
            <div
              :for={{stock, quantity, entries} <- @line_items}
              class="flex items-center gap-4.5 py-4.5 rule-fade-bottom"
            >
              <%!-- Thumbnail --%>
              <div class="shrink-0 size-[84px] rounded-field overflow-hidden bg-base-300">
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
                <.link
                  navigate={~p"/shop/item/#{stock.item.id}"}
                  class="text-lg tracking-[-0.02em] hover:text-primary transition-colors duration-150"
                >
                  {stock.item.name}
                </.link>
                <.link
                  :if={stock.studio}
                  navigate={~p"/shop/studio/#{stock.studio.id}"}
                  class="block text-[13px] text-accent hover:opacity-80 transition-opacity duration-150"
                >
                  {stock.studio.name} · {stock.studio.city}
                </.link>
                <p class="text-xs text-secondary mt-0.5">
                  {stock.price} {gettext("/ Stück")}
                </p>
              </div>

              <%!-- Qty stepper --%>
              <div class="inline-flex items-stretch overflow-hidden rounded-field border border-base-300 shrink-0">
                <button
                  phx-click="decrease_quantity"
                  phx-value-stock_id={stock.id}
                  class="px-3 hover:bg-base-content/7 transition-colors duration-150"
                >
                  <%= if quantity == 1 do %>
                    <.icon name="hero-trash" class="size-4 text-error" />
                  <% else %>
                    −
                  <% end %>
                </button>
                <span class="grid place-items-center w-9 text-sm tabular-nums border-x border-base-300">
                  {quantity}
                </span>
                <button
                  phx-click="increase_quantity"
                  phx-value-stock_id={stock.id}
                  class="px-3 hover:bg-base-content/7 transition-colors duration-150"
                >
                  +
                </button>
              </div>

              <span class="w-[120px] text-right text-base whitespace-nowrap">
                {line_total(entries)}
              </span>
            </div>

            <p :if={@shipping_note} class="text-xs text-secondary mt-4.5">
              {@shipping_note}
            </p>
          </div>

          <%!-- Summary --%>
          <div class="flex flex-col gap-3 p-5 rounded-field bg-base-100 shadow-[0_0_0_1px_var(--color-base-300)]">
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
            <div class="text-center text-[11px] text-secondary">
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

  defp shipping_note(line_items) do
    studios =
      line_items
      |> Enum.map(fn {stock, _quantity, _entries} -> stock.studio end)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq_by(& &1.id)

    if length(studios) > 1 do
      names = Enum.map_join(studios, " und ", &"#{&1.name} (#{&1.city})")
      gettext("Versand pro Studio getrennt — %{names} senden separat.", names: names)
    end
  end
end

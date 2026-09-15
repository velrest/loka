defmodule LokaWeb.Shop.ItemLive do
  alias Loka.Inventory
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket}>
      <.link
        navigate={~p"/"}
        class="text-[13px] text-secondary hover:text-base-content transition-colors duration-150"
      >
        ← {gettext("Zurück zum Markt")}
      </.link>

      <div
        id="item-slider"
        phx-hook={if @item.images != [], do: "ImageSlider"}
        class="grid grid-cols-1 lg:grid-cols-[96px_minmax(0,1fr)_minmax(0,440px)] gap-7 items-start mt-5 pb-14"
      >
        <div :if={@item.images != []} class="flex lg:flex-col gap-2.5 order-2 lg:order-1">
          <button
            :for={{image, idx} <- Enum.with_index(@item.images)}
            type="button"
            data-thumb={idx}
            class={[
              "relative aspect-square w-16 lg:w-auto rounded-field overflow-hidden bg-base-300 shrink-0",
              if(idx == 0, do: "shadow-[inset_0_0_0_1px_var(--clay-accent-700)]")
            ]}
          >
            <img src={image.path} alt="" class="w-full h-full object-cover" />
          </button>
        </div>

        <div class="relative aspect-square rounded-box overflow-hidden bg-base-300 order-1 lg:order-2">
          <img
            :if={@item.images == []}
            src="/images/placeholder-pot.svg"
            alt=""
            class="w-full h-full object-cover"
          />
          <div
            :for={{image, idx} <- Enum.with_index(@item.images)}
            data-slide={idx}
            class={[
              "absolute inset-0 transition-opacity duration-150",
              if(idx == 0, do: "opacity-100", else: "opacity-0")
            ]}
          >
            <img src={image.path} alt={@item.name} class="w-full h-full object-cover" />
          </div>
        </div>

        <div :for={stock <- @item.stock} class="order-3">
          <h6 class="m-0 mb-2.5 text-[11px] font-semibold uppercase tracking-[0.1em] text-accent">
            {gettext("Steinzeug · Unikat")}
          </h6>

          <h1 class="text-[40px] sm:text-[52px] leading-[1.02] tracking-[-0.035em] font-medium m-0 mb-1.5">
            {@item.name}
          </h1>

          <.link
            :if={stock.studio}
            navigate={~p"/shop/studio/#{stock.studio.id}"}
            class="text-[16px] text-accent hover:opacity-80 transition-opacity duration-150"
          >
            {stock.studio.name} · {stock.studio.city}
          </.link>

          <div class="rule-fade my-5"></div>

          <div class="flex items-end justify-between gap-4">
            <div data-testid="item-price">
              <div class="text-[30px] tracking-[-0.02em]">
                {stock.price}
                <span class="text-sm text-secondary">{gettext("/ Stück")}</span>
              </div>
              <p class="text-xs text-secondary mt-1">
                {ngettext(
                  "%{count} Stück verfügbar",
                  "%{count} Stücke verfügbar",
                  stock.quantity,
                  count: stock.quantity
                )}
                <%= if stock.studio do %>
                  · {gettext("Versand ab Studio %{city}", city: stock.studio.city)}
                <% end %>
              </p>
            </div>
            <.live_component
              module={LokaWeb.AddToCartComponent}
              id={"add-to-cart-#{stock.id}"}
              stock={stock}
              current_user={@current_user}
              class="btn-primary whitespace-nowrap"
            />
          </div>

          <p
            data-testid="item-description"
            class="text-[14px] leading-[1.65] text-secondary mt-6"
          >
            {@item.description}
          </p>

          <div
            :if={stock.studio}
            class="flex items-center gap-3.5 mt-6 p-3.5 rounded-field bg-base-100 shadow-[0_0_0_1px_var(--color-base-300)]"
          >
            <div class="shrink-0 size-14 rounded-field overflow-hidden bg-base-300 flex items-center justify-center">
              <%= if stock.studio.logo_path do %>
                <img
                  src={stock.studio.logo_path}
                  alt={stock.studio.name}
                  class="w-full h-full object-cover"
                />
              <% else %>
                <.icon name="hero-building-storefront" class="size-6 text-secondary" />
              <% end %>
            </div>
            <div class="flex-1 min-w-0">
              <div class="text-[15px]">{stock.studio.name}</div>
              <div class="text-[11px] text-secondary">
                {stock.studio.city} · {ngettext(
                  "%{count} weiteres Stück",
                  "%{count} weitere Stücke",
                  other_stock_count(stock.studio.id, @item.id),
                  count: other_stock_count(stock.studio.id, @item.id)
                )}
              </div>
            </div>
            <.link
              navigate={~p"/shop/studio/#{stock.studio.id}"}
              class="btn btn-secondary btn-sm whitespace-nowrap"
            >
              {gettext("Studio ansehen")}
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Inventory.get_item(id, load: [stock: :studio]) do
      {:ok, nil} ->
        {:ok,
         socket
         |> put_flash(:error, gettext("Item not found."))
         |> push_navigate(to: ~p"/")}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, gettext("Item not found."))
         |> push_navigate(to: ~p"/")}

      {:ok, item} ->
        {:ok, assign(socket, item: item)}
    end
  end

  defp other_stock_count(studio_id, item_id) do
    studio_id
    |> Inventory.list_studio_stock!()
    |> Enum.count(&(&1.item_id != item_id))
  end
end

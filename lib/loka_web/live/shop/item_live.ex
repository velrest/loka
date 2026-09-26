defmodule LokaWeb.Shop.ItemLive do
  alias Loka.Inventory
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket} locale={@locale}>
      <.back_link navigate={~p"/"}>{gettext("Zurück zum Markt")}</.back_link>

      <div
        id="item-slider"
        phx-hook={if @item.images != [], do: "ImageSlider"}
        class="grid grid-cols-1 lg:grid-cols-[96px_minmax(0,1fr)_minmax(0,440px)] gap-7 items-start mt-5 pb-14"
      >
        <.item_photos images={@item.images} name={@item.name} />

        <div class="order-3">
          <h6 class="m-0 mb-2.5 text-xs font-semibold uppercase tracking-widest text-accent">
            {gettext("Steinzeug · Unikat")}
          </h6>

          <h1 class="page-title m-0 mb-1.5">
            {@item.name}
          </h1>

          <.link
            navigate={~p"/shop/studio/#{@item.studio.id}"}
            class="text-base text-accent hover:opacity-80 transition-opacity duration-150"
          >
            {@item.studio.name} · {@item.studio.city}
          </.link>

          <div class="rule-fade my-5"></div>

          <div class="flex items-end justify-between gap-4">
            <div data-testid="item-price">
              <div :if={@item.stock} class="text-3xl tracking-tight">
                {@item.stock.price}
                <span class="text-sm text-secondary">{gettext("/ Stück")}</span>
              </div>
              <p class="text-xs text-secondary mt-1">
                <%= if @item.in_stock? do %>
                  {ngettext(
                    "%{count} Stück verfügbar",
                    "%{count} Stücke verfügbar",
                    @item.stock.quantity,
                    count: @item.stock.quantity
                  )} · {gettext("Versand ab Studio %{city}", city: @item.studio.city)}
                <% else %>
                  {if @item.stock,
                    do: gettext("Ausverkauft"),
                    else: gettext("Nicht online erhältlich")}
                <% end %>
              </p>
            </div>
            <.live_component
              :if={@item.in_stock?}
              module={LokaWeb.AddToCartComponent}
              id={"add-to-cart-#{@item.id}"}
              item={@item}
              current_user={@current_user}
              class="btn-primary whitespace-nowrap"
            />
          </div>

          <p
            data-testid="item-description"
            class="text-sm leading-relaxed text-secondary mt-6"
          >
            {@item.description}
          </p>

          <div class="flex items-center gap-3.5 mt-6 p-3.5 rounded-field bg-base-100 card-hairline">
            <div class="shrink-0 size-14 rounded-field overflow-hidden bg-base-300 flex items-center justify-center">
              <%= if @item.studio.logo_path do %>
                <img
                  src={@item.studio.logo_path}
                  alt={@item.studio.name}
                  class="w-full h-full object-cover"
                />
              <% else %>
                <.icon name="hero-building-storefront" class="size-6 text-secondary" />
              <% end %>
            </div>
            <div class="flex-1 min-w-0">
              <div class="text-base">{@item.studio.name}</div>
              <div class="text-xs text-secondary">
                {@item.studio.city} · {ngettext(
                  "%{count} weiteres Stück",
                  "%{count} weitere Stücke",
                  @other_item_count,
                  count: @other_item_count
                )}
              </div>
            </div>
            <.link
              navigate={~p"/shop/studio/#{@item.studio.id}"}
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
    case Inventory.get_item(id) do
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
        {:ok, assign(socket, item: item, other_item_count: other_item_count(item))}
    end
  end

  defp other_item_count(item) do
    item.studio_id
    |> Inventory.list_studio_items!()
    |> Enum.count(&(&1.id != item.id))
  end
end

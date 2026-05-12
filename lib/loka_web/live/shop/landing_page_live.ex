defmodule LokaWeb.Shop.LandingPageLive do
  alias Loka.Inventory
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :filtered, filtered_stock(assigns.stock, assigns.visible_studio_ids))

    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket}>
      <section class="rounded-box bg-base-200 mb-12 px-8 py-16 text-center">
        <div class="max-w-lg mx-auto">
          <span class="badge badge-primary badge-outline mb-4 tracking-widest uppercase text-xs px-3">
            {gettext("Handgefertigte Keramik")}
          </span>
          <h1 class="text-5xl font-bold leading-tight mb-4">
            {gettext("Von Hand gemacht,")}<br />{gettext("für immer geliebt")}
          </h1>
          <p class="text-base-content/60 text-lg">
            {gettext("Kleinserien-Töpferei von unabhängigen Studios.")}<br />{gettext("Jedes Stück ein Unikat.")}
          </p>
        </div>
      </section>

      <.live_component module={LokaWeb.StudioMapComponent} id="studio-map" studios={@all_studios} />

      <div class="flex items-center gap-3 mb-8">
        <h2 class="text-xs font-semibold uppercase tracking-widest text-base-content/50 whitespace-nowrap">
          {gettext("Jetzt verfügbar")}
        </h2>
        <div class="flex-1 border-t border-base-300"></div>
        <span class="text-xs text-base-content/40 whitespace-nowrap">
          {length(@filtered)} {ngettext("Stück", "Stücke", length(@filtered))}
        </span>
      </div>

      <div :if={@filtered == []} class="text-center py-24 text-base-content/40">
        <p class="text-lg">{gettext("Noch keine Artikel verfügbar.")}</p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 pb-16">
        <.stock_card :for={stock <- @filtered} stock={stock} current_user={@current_user} />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    stock = Inventory.list_all_stock!(load: [:studio, item: :images])
    studios = stock |> Enum.map(& &1.studio) |> Enum.uniq_by(& &1.id)
    {:ok, assign(socket, stock: stock, all_studios: studios, visible_studio_ids: nil)}
  end

  @impl true
  # Only filter by map bounds when zoomed in enough to be "local" (zoom >= 10).
  # Below that threshold the map shows all of Switzerland, so filtering would
  # hide studios from users who simply haven't moved the map yet.
  @local_zoom 10

  def handle_event("bounds_changed", %{"north" => n, "south" => s, "east" => e, "west" => w, "zoom" => zoom}, socket) do
    visible_ids =
      if zoom >= @local_zoom do
        socket.assigns.all_studios
        |> Enum.filter(fn studio ->
          studio.latitude && studio.longitude &&
            studio.latitude >= s && studio.latitude <= n &&
            studio.longitude >= w && studio.longitude <= e
        end)
        |> Enum.map(& &1.id)
      else
        nil
      end

    {:noreply, assign(socket, visible_studio_ids: visible_ids)}
  end

  defp filtered_stock(stock, nil), do: stock
  defp filtered_stock(stock, ids), do: Enum.filter(stock, &(&1.studio.id in ids))
end

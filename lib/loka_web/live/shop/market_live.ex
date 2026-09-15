defmodule LokaWeb.Shop.MarketLive do
  alias Loka.Inventory
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def render(assigns) do
    filtered = filtered_stock(assigns.stock, assigns.visible_studio_ids)
    studio_count = filtered |> Enum.map(& &1.studio.id) |> Enum.uniq() |> length()

    assigns = assign(assigns, filtered: filtered, studio_count: studio_count)

    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket} locale={@locale}>
      <div class="grid grid-cols-1 lg:grid-cols-[minmax(0,420px)_minmax(0,1fr)] gap-10 items-end pb-11">
        <div class="order-2 lg:order-1 pb-0 lg:pb-9">
          <h1 class="hero-title m-0 mb-3.5">
            {gettext("Von Hand")}<br />{gettext("gemacht,")}<br />
            <span class="text-primary" phx-click={JS.dispatch("loka:toggle-pioneer")}>{gettext("für immer")}</span> <br />{gettext("geliebt")}
          </h1>
          <p class="text-15 max-w-[34ch] text-secondary mb-5">
            {gettext(
              "Kleinserien-Töpferei von unabhängigen Studios in der Schweiz. Jedes Stück ein Unikat."
            )}
          </p>
          <div class="flex flex-wrap gap-2.5">
            <a href="#studio-map" class="btn btn-primary">{gettext("Studios in der Nähe")}</a>
            <a href="#available" class="btn btn-secondary">{gettext("Alle Stücke")}</a>
          </div>
        </div>

        <div class="order-1 lg:order-2">
          <.live_component
            module={LokaWeb.StudioMapComponent}
            id="studio-map"
            studios={@all_studios}
            thunderforest_key={Application.get_env(:loka, :thunderforest_api_key)}
          />
        </div>
      </div>

      <.section_header
        id="available"
        class="scroll-mt-24"
        label={gettext("Jetzt verfügbar")}
        count={
          gettext("%{count} %{stock_word} · %{studio_count} %{studio_word} im Kartenausschnitt",
            count: length(@filtered),
            stock_word: ngettext("Stück", "Stücke", length(@filtered)),
            studio_count: @studio_count,
            studio_word: ngettext("Studio", "Studios", @studio_count)
          )
        }
      />

      <.empty_state :if={@filtered == []} message={gettext("Noch keine Artikel verfügbar.")} />

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-7 py-7 pb-13">
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
  def handle_params(_unsigned_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  # Only filter by map bounds when zoomed in enough to be "local" (zoom >= 10).
  # Below that threshold the map shows all of Switzerland, so filtering would
  # hide studios from users who simply haven't moved the map yet.
  @local_zoom 10

  def handle_event(
        "bounds_changed",
        %{"north" => n, "south" => s, "east" => e, "west" => w, "zoom" => zoom},
        socket
      ) do
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

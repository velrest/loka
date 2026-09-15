defmodule LokaWeb.Shop.StudioLive do
  alias Loka.{Studios, Inventory}
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Studios.get_studio(id) do
      {:ok, nil} ->
        {:ok,
         socket
         |> put_flash(:error, gettext("Studio nicht gefunden."))
         |> push_navigate(to: ~p"/")}

      {:ok, studio} ->
        stock = Inventory.list_studio_stock!(studio.id)
        {:ok, assign(socket, studio: studio, stock: stock)}

      {:error, _} ->
        {:ok,
         socket
         |> put_flash(:error, gettext("Studio nicht gefunden."))
         |> push_navigate(to: ~p"/")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket}>
      <.back_link navigate={~p"/"}>{gettext("Zurück zum Markt")}</.back_link>

      <div class="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_420px] gap-10 items-end mt-5 mb-11">
        <div class="flex gap-5.5 items-end">
          <div class="shrink-0 size-[120px] rounded-box overflow-hidden bg-base-300 flex items-center justify-center">
            <%= if @studio.logo_path do %>
              <img src={@studio.logo_path} alt={@studio.name} class="w-full h-full object-cover" />
            <% else %>
              <.icon name="hero-building-storefront" class="size-10 text-secondary" />
            <% end %>
          </div>
          <div class="min-w-0">
            <span class="badge badge-sm badge-outline badge-primary">
              {@studio.city} · {@studio.postal_code}
            </span>
            <h1 class="page-title mt-2.5 mb-2">
              {@studio.name}
            </h1>
            <p :if={@studio.description} class="text-sm leading-[1.6] text-secondary max-w-[52ch]">
              {@studio.description}
            </p>
          </div>
        </div>

        <.live_component
          :if={@studio.latitude && @studio.longitude}
          module={LokaWeb.StudioMapComponent}
          id="studio-location"
          studios={[@studio]}
          snapshot={true}
        />
      </div>

      <.section_header
        class="mb-7"
        label={gettext("Alle Artikel")}
        count={"#{length(@stock)} #{ngettext("Stück", "Stücke", length(@stock))}"}
      />

      <.empty_state :if={@stock == []} message={gettext("Noch keine Artikel verfügbar.")} />

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-7 pb-16">
        <.stock_card :for={s <- @stock} stock={s} current_user={@current_user} show_studio={false} />
      </div>
    </Layouts.app>
    """
  end
end

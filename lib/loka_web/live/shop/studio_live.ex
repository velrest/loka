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
      <div class="mb-6">
        <.link
          navigate={~p"/"}
          class="text-sm text-base-content/50 hover:text-base-content transition-colors"
        >
          ← {gettext("Zurück zum Shop")}
        </.link>
      </div>

      <%!-- Studio header --%>
      <div class="flex items-start gap-6 mb-10 pb-10 border-b border-base-300">
        <div class="shrink-0 size-24 rounded-xl overflow-hidden bg-base-200 flex items-center justify-center">
          <%= if @studio.logo_path do %>
            <img src={@studio.logo_path} alt={@studio.name} class="w-full h-full object-cover" />
          <% else %>
            <.icon name="hero-building-storefront" class="size-10 text-base-content/30" />
          <% end %>
        </div>
        <div class="flex-1 min-w-0">
          <div class="mb-1">
            <span class="badge badge-outline badge-sm text-base-content/40">{@studio.city}</span>
          </div>
          <h1 class="text-3xl font-bold mb-2">{@studio.name}</h1>
          <p :if={@studio.description} class="text-base-content/60 leading-relaxed">
            {@studio.description}
          </p>
        </div>
      </div>

      <%!-- Stock section --%>
      <div class="flex items-center gap-3 mb-8">
        <h2 class="text-xs font-semibold uppercase tracking-widest text-base-content/50 whitespace-nowrap">
          {gettext("Alle Artikel")}
        </h2>
        <div class="flex-1 border-t border-base-300"></div>
        <span class="text-xs text-base-content/40 whitespace-nowrap">
          {length(@stock)} {ngettext("Stück", "Stücke", length(@stock))}
        </span>
      </div>

      <div :if={@stock == []} class="text-center py-24 text-base-content/40">
        <p class="text-lg">{gettext("Noch keine Artikel verfügbar.")}</p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 pb-16">
        <.stock_card :for={s <- @stock} stock={s} current_user={@current_user} show_studio={false} />
      </div>
    </Layouts.app>
    """
  end
end

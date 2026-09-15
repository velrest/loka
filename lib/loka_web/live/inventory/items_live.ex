defmodule LokaWeb.Inventory.ItemsLive do
  use LokaWeb, :live_view
  alias Loka.Inventory

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    stock =
      case Loka.Studios.get_own_studio(actor: user) do
        {:ok, %{id: studio_id}} -> Inventory.list_studio_stock!(studio_id, actor: user)
        _ -> []
      end

    {:ok, assign(socket, stock: stock)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket}>
      <:nav>
        <.inventory_tab_nav active={@current_path} />
      </:nav>

      <div class="px-4 py-10 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between mb-8">
          <h1 class="text-2xl font-bold">{gettext("Artikel")}</h1>
          <.link navigate={~p"/inventory/items/new"} class="btn btn-primary btn-sm">
            {gettext("Neuer Artikel")}
          </.link>
        </div>

        <.empty_state :if={@stock == []} message={gettext("Noch keine Artikel.")}>
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
                d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
              />
            </svg>
          </:icon>
          <:action>
            <.link navigate={~p"/inventory/items/new"} class="btn btn-primary btn-sm">
              {gettext("Neuer Artikel")}
            </.link>
          </:action>
        </.empty_state>

        <div class="flex flex-col gap-3">
          <.link
            :for={s <- @stock}
            navigate={~p"/inventory/items/#{s.id}"}
            data-item={s.id}
            class="card bg-base-100 border border-base-300 shadow shadow-black/30 hover:shadow-md transition-shadow"
          >
            <div class="card-body p-4">
              <div class="flex items-center gap-4">
                <%!-- Thumbnail --%>
                <.item_thumbnail
                  images={s.item.images}
                  alt={s.item.name}
                  class="shrink-0 size-16 rounded-lg bg-base-200"
                />

                <%!-- Info --%>
                <div class="flex-1 min-w-0">
                  <p class="font-semibold truncate">{s.item.name}</p>
                  <p class="text-sm text-base-content/50 truncate mt-0.5">{s.item.description}</p>
                </div>

                <%!-- Stats --%>
                <div class="hidden sm:flex items-center gap-6 text-sm shrink-0">
                  <div class="text-right">
                    <p class="text-base-content/40 text-xs uppercase tracking-wide">
                      {gettext("Preis")}
                    </p>
                    <p class="font-semibold">{s.price}</p>
                  </div>
                  <div class="text-right">
                    <p class="text-base-content/40 text-xs uppercase tracking-wide">
                      {gettext("Menge")}
                    </p>
                    <p class="font-semibold">{s.quantity}</p>
                  </div>
                </div>

                <%!-- Arrow --%>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="size-4 text-base-content/30 shrink-0"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
            </div>
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end
end

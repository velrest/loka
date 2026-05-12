defmodule LokaWeb.Shop.ItemLive do
  alias Loka.Inventory
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket}>
      <div class="mb-6">
        <.link navigate={~p"/"} class="text-sm text-base-content/50 hover:text-base-content transition-colors">
          ← {gettext("Zurück zum Shop")}
        </.link>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-10 pb-16 items-start">
        <%!-- Image area --%>
        <div class="relative aspect-square bg-base-200 rounded-box overflow-hidden">
          <%!-- Placeholder when no images --%>
          <img
            :if={@item.images == []}
            src="/images/placeholder-pot.svg"
            alt=""
            class="w-full h-full object-cover"
          />

          <%!-- Slider --%>
          <div
            :if={@item.images != []}
            id="item-slider"
            phx-hook="ImageSlider"
            class="relative w-full h-full"
          >
            <div
              :for={{image, idx} <- Enum.with_index(@item.images)}
              data-slide={idx}
              class={[
                "absolute inset-0 transition-opacity duration-300",
                if(idx == 0, do: "opacity-100", else: "opacity-0")
              ]}
            >
              <img src={image.path} alt={@item.name} class="w-full h-full object-cover" />
            </div>

            <div
              :if={length(@item.images) > 1}
              class="absolute inset-x-3 top-1/2 -translate-y-1/2 flex justify-between z-10"
            >
              <button
                data-action="prev"
                class="btn btn-circle bg-base-100/80 backdrop-blur-sm border-0 shadow"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="size-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
                </svg>
              </button>
              <button
                data-action="next"
                class="btn btn-circle bg-base-100/80 backdrop-blur-sm border-0 shadow"
              >
                <svg xmlns="http://www.w3.org/2000/svg" class="size-5" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
                </svg>
              </button>
            </div>

            <div
              :if={length(@item.images) > 1}
              class="absolute bottom-3 inset-x-0 flex justify-center gap-1.5 z-10"
            >
              <div
                :for={{_, idx} <- Enum.with_index(@item.images)}
                data-dot={idx}
                class={[
                  "size-2 rounded-full transition-all duration-300",
                  if(idx == 0, do: "bg-white scale-125", else: "bg-white/40")
                ]}
              />
            </div>
          </div>
        </div>

        <%!-- Details --%>
        <div class="flex flex-col gap-6">
          <div :for={stock <- @item.stock}>
            <p
              :if={stock.studio}
              class="text-xs font-medium text-primary uppercase tracking-widest opacity-70 mb-3"
            >
              {stock.studio.name}
            </p>

            <h1 class="text-3xl font-bold leading-tight">{@item.name}</h1>

            <p
              data-testid="item-description"
              class="mt-4 text-base-content/60 leading-relaxed"
            >
              {@item.description}
            </p>

            <div class="divider my-6"></div>

            <div class="flex items-center justify-between">
              <div>
                <span data-testid="item-price" class="text-2xl font-bold">{stock.price}</span>
                <span class="text-sm text-base-content/40 ml-1">{gettext("/ Stück")}</span>
                <p class="text-xs text-base-content/40 mt-1">
                  {ngettext("%{count} Stück verfügbar", "%{count} Stücke verfügbar", stock.quantity, count: stock.quantity)}
                </p>
              </div>
              <.live_component
                module={LokaWeb.AddToCartComponent}
                id={"add-to-cart-#{stock.id}"}
                stock={stock}
                current_user={@current_user}
              />
            </div>
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
end

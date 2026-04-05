defmodule LokaWeb.Shop.LandingPageLive do
  alias Loka.Inventory
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash}>
      <div class="flex flex-wrap">
        <.stock_card :for={stock <- @stock} data-item={stock.id} stock={stock} />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    stock = Inventory.list_all_stock!(load: [item: :images])
    {:ok, assign(socket, stock: stock)}
  end

  attr :stock, Inventory.Stock, required: true
  attr :rest, :global

  defp stock_card(assigns) do
    ~H"""
    <div class="card bg-base-100 w-80 shadow-sm mr-5" {@rest}>
      <figure>
        <div class="carousel w-full">
          <div
            :for={{image, index} <- Enum.with_index(@stock.item.images)}
            id={"slide_#{@stock.item.id}_#{index}"}
            class="carousel-item relative w-full"
          >
            <img
              src={image.path}
              alt={@stock.item.name}
              class="w-full"
            />
            <div class="absolute left-5 right-5 top-1/2 flex -translate-y-1/2 transform justify-between">
              <a
                href={"#slide_#{@stock.item.id}_#{if index == 0, do: length(@stock.item.images) -1, else: index - 1}"}
                class="btn btn-circle"
              >
                ❮
              </a>
              <a
                href={"#slide_#{@stock.item.id}_#{if index == length(@stock.item.images) - 1 , do: 0, else: index + 1}"}
                class="btn btn-circle"
              >
                ❯
              </a>
            </div>
          </div>
        </div>
      </figure>
      <div class="card-body">
        <h2 class="card-title">{@stock.item.name}</h2>
        <p>
          {@stock.item.description}
        </p>
        <div class="card-actions justify-between items-center">
          <span class="text-xl">{@stock.price}</span>
          <button class="btn btn-primary">{gettext("In den Warenkorb")}</button>
        </div>
      </div>
    </div>
    """
  end
end

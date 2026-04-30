defmodule LokaWeb.Shop.LandingPageLive do
  alias Loka.Inventory
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app
      current_user={@current_user}
      flash={@flash}
      socket={@socket}
    >
      <div class="flex flex-wrap">
        <.stock_card
          :for={stock <- @stock}
          data-item={stock.id}
          stock={stock}
          current_user={@current_user}
        />
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    stock = Inventory.list_all_stock!(load: [item: :images])
    {:ok, socket |> assign(stock: stock)}
  end

  attr :stock, Inventory.Stock, required: true
  attr :current_user, :any, default: nil
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
        <h2
          class="card-title"
          phx-click={JS.patch(~p"/shop/item/#{@stock.item.id}")}
        >
          {@stock.item.name}
        </h2>
        <p>
          {@stock.item.description}
        </p>
        <div class="card-actions justify-between items-center">
          <span class="text-xl">{@stock.price}</span>
          <.live_component
            module={LokaWeb.Shop.AddToCartLiveComponent}
            id={"add-to-cart-#{@stock.id}"}
            stock={@stock}
            current_user={@current_user}
          />
        </div>
      </div>
    </div>
    """
  end
end

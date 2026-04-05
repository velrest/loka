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
    stock = Inventory.list_all_stock!()
    {:ok, assign(socket, stock: stock)}
  end

  attr :stock, Inventory.Stock, required: true
  attr :rest, :global

  defp stock_card(assigns) do
    ~H"""
    <div class="card bg-base-100 w-80 shadow-sm mr-5" {@rest}>
      <figure>
        <img
          src="https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Flookaside.fbsbx.com%2Flookaside%2Fcrawler%2Fmedia%2F%3Fmedia_id%3D962791577098035&f=1&nofb=1&ipt=8f18ed6357d8760c90a1ebec72e15716b3ddc2164eeaf1d2a4ecf0b84060f5ea"
          alt="Shoes"
        />
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

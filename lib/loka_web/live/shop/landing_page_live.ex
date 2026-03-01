defmodule LokaWeb.Shop.LandingPageLive do
  alias Loka.Inventory
  use LokaWeb, :live_view

  # alias LokaWeb.Inventory

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash}>
      <div :for={item <- @items} data-item={item.id}>
        {item.name}
        {item.description}
        {item.price}
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # current_user = socket.assigns.current_user
    items = Inventory.list_all_items!()
    {:ok, assign(socket, items: items)}
  end
end

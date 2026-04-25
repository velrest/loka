defmodule LokaWeb.Inventory.ItemsLive do
  use LokaWeb, :live_view
  alias Loka.Inventory

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    stock = Inventory.list_studio_stock!(actor: user)
    {:ok, assign(socket, stock: stock)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash}>
      <:nav>
        <.inventory_tab_nav active={@current_path} />
      </:nav>

      <div class="px-4 py-10 sm:px-6 lg:px-8">
        <.header>
          {gettext("Items")}
          <:actions>
            <.link navigate={~p"/inventory/items/new"} class="btn btn-primary btn-sm">
              {gettext("New item")}
            </.link>
          </:actions>
        </.header>

        <div class="mt-8">
          <table :if={@stock != []} class="table w-full">
            <thead>
              <tr>
                <th>{gettext("Name")}</th>
                <th>{gettext("Description")}</th>
                <th>{gettext("Price")}</th>
                <th>{gettext("Quantity")}</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr :for={s <- @stock} data-item={s.id}>
                <td>{s.item.name}</td>
                <td>{s.item.description}</td>
                <td>{s.price}</td>
                <td>{s.quantity}</td>
                <td>
                  <.link navigate={~p"/inventory/items/#{s.id}"} class="btn btn-ghost btn-xs">
                    {gettext("Edit")}
                  </.link>
                </td>
              </tr>
            </tbody>
          </table>

          <p :if={@stock == []} class="text-base-content/60 text-sm mt-4">
            {gettext("No items yet. Click \"New item\" to add your first.")}
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end
end

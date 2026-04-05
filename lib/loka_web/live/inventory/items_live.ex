defmodule LokaWeb.Inventory.ItemsLive do
  use LokaWeb, :live_view
  alias Loka.Inventory

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    stock = Inventory.list_studio_stock!(actor: user)
    {:ok, assign(socket, stock: stock, show_form: false, form: nil)}
  end

  @impl true
  def handle_event("show_form", _params, socket) do
    form =
      Loka.Inventory.form_to_create_stock(actor: socket.assigns.current_user)
      |> AshPhoenix.Form.add_form(:item)
      |> to_form()

    {:noreply, assign(socket, show_form: true, form: form)}
  end

  def handle_event("hide_form", _params, socket) do
    {:noreply, assign(socket, show_form: false, form: nil)}
  end

  @impl true
  def handle_event("validate", _params, %{assigns: %{form: nil}} = socket),
    do: {:noreply, socket}

  def handle_event("validate", params, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, params["form"] || %{})
    {:noreply, assign(socket, form: to_form(form))}
  end

  @impl true
  def handle_event("save", _params, %{assigns: %{form: nil}} = socket),
    do: {:noreply, socket}

  def handle_event("save", params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params["form"] || %{}) do
      {:ok, _stock} ->
        stock = Inventory.list_studio_stock!(actor: socket.assigns.current_user)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Item created."))
         |> assign(stock: stock, show_form: false, form: nil)}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
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
            <.button :if={not @show_form} phx-click="show_form" class="btn btn-primary btn-sm">
              {gettext("New item")}
            </.button>
            <.button :if={@show_form} phx-click="hide_form" class="btn btn-ghost btn-sm">
              {gettext("Cancel")}
            </.button>
          </:actions>
        </.header>

        <div :if={@show_form} class="mt-6 max-w-sm">
          <.form for={@form} phx-change="validate" phx-submit="save" class="flex flex-col gap-4">
            <.inputs_for :let={item_form} field={@form[:item]}>
              <.input field={item_form[:name]} type="text" label={gettext("Name")} />
              <.input field={item_form[:description]} type="text" label={gettext("Description")} />
            </.inputs_for>
            <.input field={@form[:price]} type="text" label={gettext("Price (e.g. CHF 100)")} />
            <.input field={@form[:quantity]} type="number" label={gettext("Quantity")} />
            <.button type="submit" class="btn btn-primary">{gettext("Create item")}</.button>
          </.form>
        </div>

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

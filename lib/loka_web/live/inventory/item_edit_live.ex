defmodule LokaWeb.Inventory.ItemEditLive do
  use LokaWeb, :live_view
  alias Loka.Inventory
  # TODO: test

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user

    case Inventory.get_stock(id, actor: user) do
      {:ok, nil} ->
        {:ok, push_navigate(socket, to: ~p"/inventory/items")}

      {:ok, stock} ->
        stock_form =
          Loka.Inventory.form_to_update_stock(
            stock,
            actor: user,
            as: "stock"
          )
          |> to_form()

        item_form =
          Loka.Inventory.form_to_update_item(stock.item,
            actor: user,
            as: "item"
          )
          |> to_form()

        {:ok,
         assign(socket,
           stock: stock,
           stock_form: stock_form,
           item_form: item_form,
           show_confirm: false
         )}
    end
  end

  @impl true
  def handle_event("validate_stock", params, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.stock_form.source, params["stock"] || %{})
    {:noreply, assign(socket, stock_form: to_form(form))}
  end

  def handle_event("validate_item", params, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.item_form.source, params["item"] || %{})
    {:noreply, assign(socket, item_form: to_form(form))}
  end

  @impl true
  def handle_event("save_stock", params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.stock_form.source, params: params["stock"] || %{}) do
      {:ok, stock} ->
        stock_form =
          AshPhoenix.Form.for_update(stock, :update_stock,
            actor: socket.assigns.current_user,
            as: "stock"
          )
          |> to_form()

        {:noreply,
         socket
         |> put_flash(:info, gettext("Pricing and stock updated."))
         |> assign(stock: stock, stock_form: stock_form)}

      {:error, form} ->
        {:noreply, assign(socket, stock_form: to_form(form))}
    end
  end

  def handle_event("save_item", params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.item_form.source, params: params["item"] || %{}) do
      {:ok, item} ->
        item_form =
          AshPhoenix.Form.for_update(item, :update_item,
            actor: socket.assigns.current_user,
            as: "item"
          )
          |> to_form()

        {:noreply,
         socket
         |> put_flash(:info, gettext("Item details updated."))
         |> assign(item_form: item_form)}

      {:error, form} ->
        {:noreply, assign(socket, item_form: to_form(form))}
    end
  end

  @impl true
  def handle_event("request_delete", _params, socket) do
    {:noreply, assign(socket, show_confirm: true)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, show_confirm: false)}
  end

  def handle_event("delete", _params, socket) do
    case Inventory.archive_stock(socket.assigns.stock, actor: socket.assigns.current_user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Item archived."))
         |> push_navigate(to: ~p"/inventory/items")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Could not archive item."))
         |> assign(show_confirm: false)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash}>
      <:nav>
        <.inventory_tab_nav active={@current_path} />
      </:nav>

      <div class="px-4 py-10 sm:px-6 lg:px-8 max-w-sm">
        <.header>
          {@stock.item.name}
          <:subtitle>
            <.link
              navigate={~p"/inventory/items"}
              class="text-sm text-base-content/60 hover:underline"
            >
              ← {gettext("Back to items")}
            </.link>
          </:subtitle>
        </.header>

        <div class="mt-6 flex flex-col gap-10">
          <div>
            <h3 class="font-semibold mb-4">{gettext("Item details")}</h3>
            <.form
              for={@item_form}
              phx-change="validate_item"
              phx-submit="save_item"
              class="flex flex-col gap-4"
            >
              <.input field={@item_form[:name]} type="text" label={gettext("Name")} />
              <.input field={@item_form[:description]} type="text" label={gettext("Description")} />
              <.button type="submit" class="btn btn-primary">
                {gettext("Save item details")}
              </.button>
            </.form>
          </div>

          <div>
            <h3 class="font-semibold mb-4">{gettext("Pricing & stock")}</h3>
            <.form
              for={@stock_form}
              phx-change="validate_stock"
              phx-submit="save_stock"
              class="flex flex-col gap-4"
            >
              <.input field={@stock_form[:price]} type="text" label={gettext("Price")} />
              <.input field={@stock_form[:quantity]} type="number" label={gettext("Quantity")} />
              <.button type="submit" class="btn btn-primary">
                {gettext("Save pricing & stock")}
              </.button>
            </.form>
          </div>
        </div>

        <div class="mt-12 border-t border-error/20 pt-6">
          <.button phx-click="request_delete" class="btn btn-outline btn-error btn-sm">
            {gettext("Archive item")}
          </.button>
        </div>
      </div>

      <dialog class={["modal", @show_confirm && "modal-open"]}>
        <div class="modal-box">
          <h3 class="text-lg font-bold">{gettext("Archive this item?")}</h3>
          <p class="py-4 text-base-content/70">
            {gettext(
              "This item will be archived and no longer visible to customers. Your data is retained and can be restored by contacting support."
            )}
          </p>
          <div class="modal-action">
            <.button phx-click="cancel_delete" class="btn btn-ghost">
              {gettext("Cancel")}
            </.button>
            <.button phx-click="delete" class="btn btn-error">
              {gettext("Yes, archive")}
            </.button>
          </div>
        </div>
        <div class="modal-backdrop" phx-click="cancel_delete" />
      </dialog>
    </Layouts.app>
    """
  end
end

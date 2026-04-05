defmodule LokaWeb.Inventory.ItemEditLive do
  use LokaWeb, :live_view
  alias Loka.Inventory
  # TODO
  # Merge this so it's the same form ;)

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user

    case Inventory.get_stock(id, actor: user) do
      {:ok, nil} ->
        {:ok, push_navigate(socket, to: ~p"/inventory/items")}

      {:error, _} ->
        {:ok, push_navigate(socket, to: ~p"/inventory/items")}

      {:ok, stock} ->
        stock_form =
          Loka.Inventory.form_to_update_stock(stock, actor: user, as: "stock")
          |> to_form()

        item_form =
          Loka.Inventory.form_to_update_item(stock.item, actor: user, as: "item")
          |> to_form()

        images = Inventory.list_item_images!(stock.item.id)

        socket =
          socket
          |> assign(
            mode: :edit,
            stock: stock,
            stock_form: stock_form,
            item_form: item_form,
            show_confirm: false
          )
          |> stream(:images, images)
          |> allow_upload(:images,
            accept: ~w[.jpg .jpeg .png .webp],
            max_entries: 5,
            auto_upload: true
          )

        {:ok, socket}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    form =
      Loka.Inventory.form_to_create_stock(actor: user)
      |> AshPhoenix.Form.add_form(:item)
      |> to_form()

    socket =
      socket
      |> assign(mode: :create, form: form, show_confirm: false)
      |> stream(:images, [])
      |> allow_upload(:images,
        accept: ~w[.jpg .jpeg .png .webp],
        max_entries: 5,
        auto_upload: true
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", params, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, params["form"])
    {:noreply, assign(socket, form: to_form(form))}
  end

  def handle_event("save", params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params["form"]) do
      {:ok, stock} ->
        socket = consume_and_save_images(socket, stock.item_id)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Item created."))
         |> push_navigate(to: ~p"/inventory/items")}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def handle_event("validate_stock", params, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.stock_form.source, params["stock"])
    {:noreply, assign(socket, stock_form: to_form(form))}
  end

  def handle_event("validate_item", params, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.item_form.source, params["item"])
    {:noreply, assign(socket, item_form: to_form(form))}
  end

  @impl true
  def handle_event("save_stock", params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.stock_form.source, params: params["stock"]) do
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
    case AshPhoenix.Form.submit(socket.assigns.item_form.source, params: params["item"]) do
      {:ok, item} ->
        socket = consume_and_save_images(socket, item.id)

        item_form =
          AshPhoenix.Form.for_update(item, :update_item,
            actor: socket.assigns.current_user,
            as: "item"
          )
          |> to_form()

        images = Inventory.list_item_images!(item.id)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Item details updated."))
         |> assign(item_form: item_form)
         |> stream(:images, images)}

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

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :images, ref)}
  end

  def handle_event("remove_image", %{"id" => id}, socket) do
    case Enum.find(socket.assigns.images, &(&1.id == id)) do
      nil ->
        {:noreply, socket}

      image ->
        case Inventory.delete_image(image, actor: socket.assigns.current_user) do
          :ok ->
            {:noreply, stream_delete(socket, :images, image)}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, gettext("Could not remove image."))}
        end
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
          {if @mode == :create, do: gettext("New item"), else: @stock.item.name}
          <:subtitle>
            <.link
              navigate={~p"/inventory/items"}
              class="text-sm text-base-content/60 hover:underline"
            >
              ← {gettext("Back to items")}
            </.link>
          </:subtitle>
        </.header>

        <div :if={@mode == :create} class="mt-6">
          <.form for={@form} phx-change="validate" phx-submit="save" class="flex flex-col gap-4">
            <.inputs_for :let={item_form} field={@form[:item]}>
              <.input field={item_form[:name]} type="text" label={gettext("Name")} />
              <.input field={item_form[:description]} type="text" label={gettext("Description")} />
            </.inputs_for>
            <.input field={@form[:price]} type="text" label={gettext("Price (e.g. CHF 100)")} />
            <.input field={@form[:quantity]} type="number" label={gettext("Quantity")} />

            <div>
              <p class="text-sm font-medium mb-2">
                {gettext("Images")} <span class="text-error">*</span>
              </p>
              <div class="flex flex-wrap gap-2 mb-2">
                <div :for={entry <- @uploads.images.entries} class="relative">
                  <.live_img_preview entry={entry} class="w-20 h-20 object-cover rounded" />
                  <button
                    type="button"
                    phx-click="cancel_upload"
                    phx-value-ref={entry.ref}
                    class="absolute -top-1 -right-1 btn btn-circle btn-xs btn-error"
                  >
                    ×
                  </button>
                </div>
              </div>
              <.live_file_input
                upload={@uploads.images}
                class="file-input file-input-bordered w-full"
              />
            </div>

            <.button
              type="submit"
              class="btn btn-primary"
              disabled={@uploads.images.entries == []}
            >
              {gettext("Create item")}
            </.button>
          </.form>
        </div>

        <div :if={@mode == :edit} class="mt-6 flex flex-col gap-10">
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

              <div>
                <p class="text-sm font-medium mb-2">
                  {gettext("Images")} <span class="text-error">*</span>
                </p>
                <div class="flex flex-wrap gap-2 mb-2">
                  <div :for={image <- @images} class="relative">
                    <img src={image.path} class="w-20 h-20 object-cover rounded" />
                    <button
                      type="button"
                      phx-click="remove_image"
                      phx-value-id={image.id}
                      class="absolute -top-1 -right-1 btn btn-circle btn-xs btn-error"
                    >
                      Remove
                    </button>
                  </div>
                  <div :for={entry <- @uploads.images.entries} class="relative">
                    <.live_img_preview entry={entry} class="w-20 h-20 object-cover rounded" />
                    <button
                      type="button"
                      phx-click="cancel_upload"
                      phx-value-ref={entry.ref}
                      class="absolute -top-1 -right-1 btn btn-circle btn-xs btn-error"
                    >
                      ×
                    </button>
                  </div>
                </div>
                <.live_file_input
                  upload={@uploads.images}
                  class="file-input file-input-bordered w-full"
                />
              </div>

              <.button
                type="submit"
                class="btn btn-primary"
                disabled={@images == [] and @uploads.images.entries == []}
              >
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

        <div :if={@mode == :edit} class="mt-12 border-t border-error/20 pt-6">
          <.button phx-click="request_delete" class="btn btn-outline btn-error btn-sm">
            {gettext("Archive item")}
          </.button>
        </div>
      </div>

      <dialog :if={@mode == :edit} class={["modal", @show_confirm && "modal-open"]}>
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

  defp consume_and_save_images(socket, item_id) do
    existing_count = length(socket.assigns.images)

    consume_uploaded_entries(socket, :images, fn %{path: tmp_path}, entry ->
      dest_dir = Path.join([:code.priv_dir(:loka), "static", "uploads", "items", item_id])
      File.mkdir_p!(dest_dir)
      filename = "#{Ecto.UUID.generate()}#{Path.extname(entry.client_name)}"
      dest = Path.join(dest_dir, filename)
      File.cp!(tmp_path, dest)
      {:ok, %{path: ~p"/uploads/items/#{item_id}/#{filename}", filename: entry.client_name}}
    end)
    |> Enum.with_index(existing_count)
    |> Enum.each(fn {%{path: path, filename: filename}, position} ->
      Inventory.create_image!(
        %{path: path, filename: filename, position: position, item_id: item_id},
        actor: socket.assigns.current_user
      )
    end)

    socket
  end
end

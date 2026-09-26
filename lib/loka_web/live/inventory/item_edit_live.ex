defmodule LokaWeb.Inventory.ItemEditLive do
  use LokaWeb, :live_view
  alias Loka.Inventory

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user

    case Inventory.get_own_item(id, actor: user, load: [:stock]) do
      {:ok, %Inventory.Item{} = item} ->
        item_form =
          Loka.Inventory.form_to_update_item(item, actor: user, as: "item")
          |> to_form()

        images = Inventory.list_item_images!(item.id)

        socket =
          socket
          |> assign(
            mode: :edit,
            item: item,
            item_form: item_form,
            show_confirm: false,
            image_count: length(images)
          )
          |> assign_stock(item.stock)
          |> stream(:images, images)
          |> allow_upload(:images,
            accept: ~w[.jpg .jpeg .png .webp],
            max_entries: 5,
            auto_upload: true
          )

        {:ok, socket}

      _ ->
        {:ok, push_navigate(socket, to: ~p"/inventory/items")}
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    case Loka.Studios.get_own_studio(actor: user) do
      {:ok, nil} -> {:ok, push_navigate(socket, to: ~p"/inventory/studio")}
      _ -> mount_create(socket, user)
    end
  end

  defp mount_create(socket, user) do
    form =
      Loka.Inventory.form_to_create_item(actor: user)
      |> AshPhoenix.Form.add_form(:stock)
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
      {:ok, item} ->
        save_image(socket, item.id)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Artikel erstellt."))
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
        message =
          if socket.assigns.stock,
            do: gettext("Preis und Bestand aktualisiert."),
            else: gettext("Artikel wird zum Verkauf angeboten.")

        {:noreply,
         socket
         |> put_flash(:info, message)
         |> assign_stock(stock)}

      {:error, form} ->
        {:noreply, assign(socket, stock_form: to_form(form))}
    end
  end

  def handle_event("save_item", params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.item_form.source, params: params["item"]) do
      {:ok, item} ->
        item_form =
          AshPhoenix.Form.for_update(item, :update_item,
            actor: socket.assigns.current_user,
            as: "item"
          )
          |> to_form()

        {:noreply,
         socket
         |> save_image(item.id)
         |> put_flash(:info, gettext("Artikeldetails aktualisiert."))
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

  def handle_event("unlist", _params, socket) do
    case Inventory.archive_stock(socket.assigns.stock, actor: socket.assigns.current_user) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Artikel vom Verkauf genommen."))
         |> assign_stock(nil)}

      {:error, _} ->
        {:noreply,
         put_flash(socket, :error, gettext("Artikel konnte nicht vom Verkauf genommen werden."))}
    end
  end

  def handle_event("delete", _params, socket) do
    case Inventory.archive_item(socket.assigns.item, actor: socket.assigns.current_user) do
      :ok ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Artikel archiviert."))
         |> push_navigate(to: ~p"/inventory/items")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Artikel konnte nicht archiviert werden."))
         |> assign(show_confirm: false)}
    end
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :images, ref)}
  end

  def handle_event("remove_image", _params, %{assigns: %{image_count: count}} = socket)
      when count <= 1 do
    {:noreply, put_flash(socket, :error, gettext("Mindestens ein Bild ist erforderlich."))}
  end

  def handle_event("remove_image", %{"id" => id}, socket) do
    user = socket.assigns.current_user

    case Inventory.get_image(id, actor: user) do
      {:ok, nil} ->
        {:noreply, socket}

      {:ok, image} ->
        case Inventory.delete_image(image, actor: user) do
          :ok ->
            {:noreply,
             socket
             |> stream_delete(:images, image)
             |> update(:image_count, &(&1 - 1))}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, gettext("Bild konnte nicht entfernt werden."))}
        end

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket} locale={@locale}>
      <:nav>
        <.inventory_tab_nav active={@current_path} partial_match?={true} />
      </:nav>

      <div class="px-4 py-10 sm:px-6 lg:px-8">
        <%!-- Header --%>
        <div class="mb-8">
          <.link
            navigate={~p"/inventory/items"}
            class="text-sm text-base-content/50 hover:text-base-content transition-colors"
          >
            ← {gettext("Zurück zu Artikeln")}
          </.link>
          <h1 class="text-2xl font-bold mt-3">
            {if @mode == :create, do: gettext("Neuer Artikel"), else: @item.name}
          </h1>
        </div>

        <%!-- Create mode --%>
        <div :if={@mode == :create} class="max-w-lg">
          <.form for={@form} phx-change="validate" phx-submit="save" class="flex flex-col gap-5">
            <.input field={@form[:name]} type="text" label={gettext("Name")} />
            <.input
              field={@form[:description]}
              type="textarea"
              label={gettext("Beschreibung")}
              rows="3"
            />

            <.inputs_for :let={stock_form} field={@form[:stock]}>
              <div class="grid grid-cols-2 gap-4">
                <.input
                  field={stock_form[:price]}
                  type="text"
                  label={gettext("Preis (z.B. CHF 100)")}
                />
                <.input field={stock_form[:quantity]} type="number" label={gettext("Menge")} />
              </div>
            </.inputs_for>

            <div>
              <p class="text-sm font-medium mb-2">
                {gettext("Bilder")} <span class="text-error">*</span>
              </p>
              <div class="flex flex-wrap gap-2 mb-3">
                <div :for={entry <- @uploads.images.entries} class="relative">
                  <.live_img_preview entry={entry} class="size-20 object-cover rounded-lg" />
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

            <.button type="submit" class="btn btn-primary" disabled={@uploads.images.entries == []}>
              {gettext("Artikel erstellen")}
            </.button>
          </.form>
        </div>

        <%!-- Edit mode --%>
        <div :if={@mode == :edit} class="grid grid-cols-1 lg:grid-cols-2 gap-10 items-start">
          <%!-- Left: images --%>
          <div
            id="image-upload-card"
            class="card bg-base-100 border border-base-300 shadow shadow-black/30"
          >
            <div class="card-body gap-4">
              <h3 class="font-semibold">{gettext("Bilder")}</h3>

              <%!-- Image gallery --%>
              <div id="item-images" phx-update="stream" class="grid grid-cols-3 gap-2">
                <div
                  :for={{dom_id, image} <- @streams.images}
                  id={dom_id}
                  class="relative group aspect-square"
                >
                  <img src={image.path} class="w-full h-full object-cover rounded-lg" />
                  <button
                    :if={@image_count > 1}
                    type="button"
                    phx-click="remove_image"
                    phx-value-id={image.id}
                    class="absolute inset-0 flex items-center justify-center bg-black/50 rounded-lg opacity-0 group-hover:opacity-100 transition-opacity text-white text-xs font-medium"
                  >
                    {gettext("Entfernen")}
                  </button>
                </div>
              </div>

              <%!-- Upload previews --%>
              <div :if={@uploads.images.entries != []} class="grid grid-cols-3 gap-2">
                <div :for={entry <- @uploads.images.entries} class="relative aspect-square">
                  <.live_img_preview entry={entry} class="w-full h-full object-cover rounded-lg" />
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
          </div>

          <%!-- Right: forms --%>
          <div class="flex flex-col gap-6">
            <%!-- Item details --%>
            <div class="card bg-base-100 border border-base-300 shadow shadow-black/30">
              <div class="card-body gap-4">
                <h3 class="font-semibold">{gettext("Artikeldetails")}</h3>
                <.form
                  for={@item_form}
                  phx-change="validate_item"
                  phx-submit="save_item"
                  class="flex flex-col gap-4"
                >
                  <.input field={@item_form[:name]} type="text" label={gettext("Name")} />
                  <.input
                    field={@item_form[:description]}
                    type="textarea"
                    label={gettext("Beschreibung")}
                    rows="4"
                  />
                  <.button type="submit" class="btn btn-primary btn-sm self-end">
                    {gettext("Speichern")}
                  </.button>
                </.form>
              </div>
            </div>

            <%!-- Price & stock --%>
            <div class="card bg-base-100 border border-base-300 shadow shadow-black/30">
              <div class="card-body gap-4">
                <h3 class="font-semibold">{gettext("Preis & Bestand")}</h3>
                <p :if={!@stock} class="text-sm text-base-content/50">
                  {gettext(
                    "Dieser Artikel ist nicht im Verkauf. Gib Preis und Menge an, um ihn anzubieten."
                  )}
                </p>
                <.form
                  for={@stock_form}
                  phx-change="validate_stock"
                  phx-submit="save_stock"
                  class="flex flex-col gap-4"
                >
                  <div class="grid grid-cols-2 gap-4">
                    <.input field={@stock_form[:price]} type="text" label={gettext("Preis")} />
                    <.input field={@stock_form[:quantity]} type="number" label={gettext("Menge")} />
                  </div>
                  <div class="flex justify-end gap-2">
                    <.button
                      :if={@stock}
                      type="button"
                      phx-click="unlist"
                      class="btn btn-ghost btn-sm"
                    >
                      {gettext("Vom Verkauf nehmen")}
                    </.button>
                    <.button type="submit" class="btn btn-primary btn-sm">
                      {if @stock, do: gettext("Speichern"), else: gettext("Zum Verkauf anbieten")}
                    </.button>
                  </div>
                </.form>
              </div>
            </div>

            <%!-- Danger zone --%>
            <div class="card bg-base-100 border border-error/20 shadow shadow-black/30">
              <div class="card-body gap-2">
                <h3 class="font-semibold text-error/80">{gettext("Gefahrenzone")}</h3>
                <p class="text-sm text-base-content/50">
                  {gettext("Archivierte Artikel sind für Kunden nicht mehr sichtbar.")}
                </p>
                <div class="mt-2">
                  <.button phx-click="request_delete" class="btn btn-outline btn-error btn-sm">
                    {gettext("Artikel archivieren")}
                  </.button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <dialog :if={@mode == :edit} class={["modal", @show_confirm && "modal-open"]}>
        <div class="modal-box">
          <h3 class="text-lg font-bold">{gettext("Diesen Artikel archivieren?")}</h3>
          <p class="py-4 text-base-content/70">
            {gettext(
              "Dieser Artikel wird archiviert und ist für Kunden nicht mehr sichtbar. Du kannst ihn in deiner Artikelliste jederzeit wiederherstellen."
            )}
          </p>
          <div class="modal-action">
            <.button phx-click="cancel_delete" class="btn btn-ghost">
              {gettext("Abbrechen")}
            </.button>
            <.button phx-click="delete" class="btn btn-error">
              {gettext("Ja, archivieren")}
            </.button>
          </div>
        </div>
        <div class="modal-backdrop" phx-click="cancel_delete" />
      </dialog>
    </Layouts.app>
    """
  end

  # Edits the current stock in place, or offers a create form when the item
  # isn't on sale
  defp assign_stock(socket, stock) do
    user = socket.assigns.current_user

    form =
      if stock do
        Loka.Inventory.form_to_update_stock(stock, actor: user, as: "stock")
      else
        item_id = socket.assigns.item.id

        Loka.Inventory.form_to_create_stock(
          actor: user,
          as: "stock",
          transform_params: fn _form, params, _type -> Map.put(params, "item_id", item_id) end
        )
      end

    assign(socket, stock: stock, stock_form: to_form(form))
  end

  defp save_image(socket, item_id) do
    new_images =
      consume_uploaded_entries(socket, :images, fn %{path: tmp_path}, entry ->
        file = %Plug.Upload{path: tmp_path, filename: entry.client_name}
        {:ok, Inventory.create_image!(item_id, file, %{}, actor: socket.assigns.current_user)}
      end)

    socket
    |> stream(:images, new_images, reset: false)
    |> then(fn s ->
      if s.assigns[:image_count] != nil do
        update(s, :image_count, &(&1 + length(new_images)))
      else
        s
      end
    end)
  end
end

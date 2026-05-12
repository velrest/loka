defmodule LokaWeb.Inventory.StudioLive do
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    case Loka.Studios.get_own_studio(actor: socket.assigns.current_user) do
      {:ok, nil} ->
        {:ok, push_navigate(socket, to: ~p"/me/studio")}

      {:ok, studio} ->
        form =
          Loka.Studios.form_to_update_studio(
            studio,
            actor: socket.assigns.current_user,
            as: "studio"
          )
          |> to_form()

        last_params =
          Map.new([:name, :street, :house_number, :city, :postal_code, :description], fn field ->
            {to_string(field), Map.get(studio, field)}
          end)

        {:ok,
         socket
         |> assign(
           studio: studio,
           form: form,
           saved: false,
           show_confirm: false,
           last_params: last_params
         )
         |> allow_upload(:logo,
           accept: ~w[.jpg .jpeg .png .webp],
           max_entries: 1,
           auto_upload: true
         )}
    end
  end

  @impl true
  def handle_info(:clear_saved, socket) do
    {:noreply, assign(socket, saved: false)}
  end

  def handle_info({:city_selected, %{city: city, zip: zip}}, socket) do
    params = Map.merge(socket.assigns.last_params, %{"city" => city, "postal_code" => zip})
    form = AshPhoenix.Form.validate(socket.assigns.form.source, params)
    {:noreply, assign(socket, form: to_form(form), last_params: params)}
  end

  @impl true
  def handle_event("request_delete", _params, socket) do
    {:noreply, assign(socket, show_confirm: true)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, show_confirm: false)}
  end

  def handle_event("delete", _params, socket) do
    case Loka.Studios.archive_studio(socket.assigns.studio, actor: socket.assigns.current_user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Studio gelöscht."))
         |> push_navigate(to: ~p"/me/studio")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Studio konnte nicht gelöscht werden."))
         |> assign(show_confirm: false)}
    end
  end

  @impl true
  def handle_event("validate", _params, %{assigns: %{form: nil}} = socket),
    do: {:noreply, socket}

  def handle_event("validate", params, socket) do
    raw = params["studio"] || %{}
    form = AshPhoenix.Form.validate(socket.assigns.form.source, raw)
    {:noreply, assign(socket, form: to_form(form), last_params: raw)}
  end

  @impl true
  def handle_event("save", _params, %{assigns: %{form: nil}} = socket),
    do: {:noreply, socket}

  def handle_event("save", params, socket) do
    user = socket.assigns.current_user

    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params["studio"] || %{}) do
      {:ok, studio} ->
        studio = consume_logo_upload(socket, studio, user)

        form =
          AshPhoenix.Form.for_update(studio, :update_studio, actor: user, as: "studio")
          |> to_form()

        Process.send_after(self(), :clear_saved, 2000)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Studio gespeichert."))
         |> assign(studio: studio, form: form, saved: true)}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  defp consume_logo_upload(socket, studio, user) do
    case consume_uploaded_entries(socket, :logo, fn %{path: tmp_path}, entry ->
           file = %Plug.Upload{
             path: tmp_path,
             filename: entry.client_name,
             content_type: entry.client_type
           }

           {:ok, Loka.Studios.update_studio!(studio, %{logo: file}, actor: user)}
         end) do
      [] -> studio
      [updated] -> updated
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket}>
      <:nav>
        <.inventory_tab_nav active={@current_path} />
      </:nav>

      <div class="px-4 py-10 sm:px-6 lg:px-8 max-w-lg">
        <div class="mb-8">
          <h1 class="text-2xl font-bold">{gettext("Studio verwalten")}</h1>
        </div>

        <.form for={@form} phx-change="validate" phx-submit="save" class="flex flex-col gap-6">
          <%!-- Card 1: Studio details --%>
          <div class="card bg-base-100 border border-base-300 shadow shadow-black/30">
            <div class="card-body gap-4">
              <h3 class="font-semibold">{gettext("Studiodetails")}</h3>

              <%!-- Logo --%>
              <div class="flex items-center gap-4">
                <div class="shrink-0 size-20 rounded-xl overflow-hidden bg-base-200 flex items-center justify-center">
                  <%= if entry = List.first(@uploads.logo.entries) do %>
                    <.live_img_preview entry={entry} class="w-full h-full object-cover" />
                  <% else %>
                    <%= if @studio.logo_path do %>
                      <img src={@studio.logo_path} alt="" class="w-full h-full object-cover" />
                    <% else %>
                      <.icon name="hero-building-storefront" class="size-8 text-base-content/30" />
                    <% end %>
                  <% end %>
                </div>
                <div class="flex-1">
                  <p class="text-sm font-medium mb-1">{gettext("Logo")}</p>
                  <.live_file_input
                    upload={@uploads.logo}
                    class="file-input file-input-sm file-input-bordered w-full"
                  />
                  <p class="text-xs text-base-content/40 mt-1">
                    {gettext("JPG, PNG oder WEBP")}
                  </p>
                </div>
              </div>

              <.input field={@form[:name]} type="text" label={gettext("Studioname")} />

              <.input
                field={@form[:description]}
                type="textarea"
                label={gettext("Beschreibung")}
                rows="3"
              />
            </div>
          </div>

          <%!-- Card 2: Location --%>
          <div class="card bg-base-100 border border-base-300 shadow shadow-black/30">
            <div class="card-body gap-4">
              <h3 class="font-semibold">{gettext("Standort")}</h3>

              <div class="grid grid-cols-3 gap-3">
                <div class="col-span-2">
                  <.input field={@form[:street]} type="text" label={gettext("Strasse")} />
                </div>
                <.input field={@form[:house_number]} type="text" label={gettext("Nr.")} />
              </div>

              <.live_component
                module={LokaWeb.AddressInputComponent}
                id="address-input"
                postal_code_field={@form[:postal_code]}
                city_field={@form[:city]}
              />

              <div :if={@studio.latitude && @studio.longitude} class="pt-1">
                <div
                  id="studio-location-map"
                  phx-hook=".StudioLocationMap"
                  data-lat={@studio.latitude}
                  data-lng={@studio.longitude}
                  class="h-48 w-full rounded-lg overflow-hidden"
                  style="z-index: 0"
                />
              </div>
              <p :if={!@studio.latitude || !@studio.longitude} class="text-sm text-base-content/40">
                {gettext("Keine Koordinaten verfügbar.")}
              </p>
            </div>
          </div>

          <%!-- Save button --%>
          <div class="flex justify-end">
            <.button type="submit" class={["btn btn-primary", @saved && "btn-success"]}>
              <.icon :if={@saved} name="hero-check" class="size-4" />
              {if @saved, do: gettext("Gespeichert!"), else: gettext("Speichern")}
            </.button>
          </div>
        </.form>

        <%!-- Danger zone --%>
        <div class="card bg-base-100 border border-error/20 shadow shadow-black/30 mt-6">
          <div class="card-body gap-2">
            <h3 class="font-semibold text-error/80">{gettext("Gefahrenzone")}</h3>
            <p class="text-sm text-base-content/50">
              {gettext("Archivierte Studios sind für Kunden nicht mehr sichtbar.")}
            </p>
            <div class="mt-2">
              <.button phx-click="request_delete" class="btn btn-outline btn-error btn-sm">
                {gettext("Studio archivieren")}
              </.button>
            </div>
          </div>
        </div>
      </div>

      <dialog class={["modal", @show_confirm && "modal-open"]}>
        <div class="modal-box">
          <h3 class="text-lg font-bold">{gettext("Studio archivieren?")}</h3>
          <p class="py-4 text-base-content/70">
            {gettext(
              "Dein Studio wird archiviert und ist weder für dich noch für Kunden sichtbar. Deine Daten bleiben erhalten und können über den Support wiederhergestellt werden."
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

    <script :type={Phoenix.LiveView.ColocatedHook} name=".StudioLocationMap">
      import L from "leaflet"

      export default {
        _map: null,
        mounted() { this._init() },
        updated() {
          if (this._map) { this._map.remove(); this._map = null }
          this._init()
        },
        _init() {
          const lat = parseFloat(this.el.dataset.lat)
          const lng = parseFloat(this.el.dataset.lng)
          this._map = L.map(this.el, {
            zoomControl: false,
            dragging: false,
            scrollWheelZoom: false,
            doubleClickZoom: false,
            touchZoom: false,
            keyboard: false,
            attributionControl: false
          }).setView([lat, lng], 14)
          L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', { maxZoom: 19 }).addTo(this._map)
          L.marker([lat, lng]).addTo(this._map)
        }
      }
    </script>
    """
  end
end

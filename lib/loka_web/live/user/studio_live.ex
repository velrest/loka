defmodule LokaWeb.User.StudioLive do
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, studio} = Loka.Studios.get_own_studio(actor: socket.assigns.current_user)

    {:ok, assign(socket, studio: studio, show_form: false, form: nil)}
  end

  @impl true
  def handle_event("show_form", _params, socket) do
    form =
      Loka.Studios.form_to_create_studio(
        actor: socket.assigns.current_user,
        as: "studio"
      )

    {:noreply, assign(socket, show_form: true, form: to_form(form))}
  end

  @impl true
  def handle_event("validate", _params, %{assigns: %{form: nil}} = socket),
    do: {:noreply, socket}

  def handle_event("validate", params, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, params["studio"] || %{})
    {:noreply, assign(socket, form: to_form(form))}
  end

  @impl true
  def handle_event("save", _params, %{assigns: %{form: nil}} = socket),
    do: {:noreply, socket}

  def handle_event("save", params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params["studio"] || %{}) do
      {:ok, studio} ->
        {:noreply, assign(socket, studio: studio, show_form: false, form: nil)}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket}>
      <:nav>
        <.profile_tab_nav active={@current_path} />
      </:nav>

      <%!-- Has studio --%>
      <div :if={@studio} class="px-4 py-10 sm:px-6 lg:px-8 max-w-lg">
        <div class="mb-8">
          <h1 class="text-2xl font-bold">{gettext("Studio")}</h1>
        </div>

        <div class="card bg-base-100 border border-base-300 shadow shadow-black/30">
          <div class="card-body gap-3">
            <div class="flex items-center gap-3">
              <div class="bg-primary/10 text-primary rounded-xl p-3">
                <.icon name="hero-building-storefront" class="size-6" />
              </div>
              <div>
                <p class="font-semibold">{@studio.name}</p>
                <p class="text-xs text-base-content/50">{gettext("Aktiv")}</p>
              </div>
            </div>
            <div class="pt-2">
              <.link navigate={~p"/inventory/studio"} class="btn btn-primary btn-sm">
                {gettext("Studio verwalten")}
              </.link>
            </div>
          </div>
        </div>
      </div>

      <%!-- Create form --%>
      <div :if={!@studio && @show_form} class="px-4 py-10 sm:px-6 lg:px-8 max-w-lg">
        <div class="mb-8">
          <h1 class="text-2xl font-bold">{gettext("Studio eröffnen")}</h1>
        </div>

        <div class="card bg-base-100 border border-base-300 shadow shadow-black/30">
          <div class="card-body gap-4">
            <h3 class="font-semibold">{gettext("Studioname wählen")}</h3>
            <p class="text-sm text-base-content/50">{gettext("Kann jederzeit geändert werden.")}</p>
            <.form for={@form} phx-change="validate" phx-submit="save" class="flex flex-col gap-4">
              <.input field={@form[:name]} type="text" label={gettext("Studioname")} />

              <div class="divider my-0 text-xs text-base-content/40">{gettext("Adresse")}</div>

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

              <.button type="submit" class="btn btn-primary self-end">
                {gettext("Studio erstellen")}
              </.button>
            </.form>
          </div>
        </div>
      </div>

      <%!-- Empty state --%>
      <div :if={!@studio && !@show_form} class="flex flex-col items-center justify-center py-24 gap-6 text-center max-w-sm mx-auto">
        <div class="bg-primary/10 text-primary rounded-2xl p-6">
          <.icon name="hero-building-storefront" class="size-14" />
        </div>

        <div class="flex flex-col gap-2">
          <h2 class="text-3xl font-bold tracking-tight">{gettext("Dein Studio wartet")}</h2>
          <p class="text-base-content/60 text-sm leading-relaxed">
            {gettext("Erreiche neue Kunden, zeige dein Handwerk und baue etwas, das Menschen begeistert.")}
          </p>
        </div>

        <.button phx-click="show_form" class="btn btn-primary btn-wide mt-2">
          {gettext("Studio eröffnen")}
        </.button>
      </div>
    </Layouts.app>
    """
  end
end

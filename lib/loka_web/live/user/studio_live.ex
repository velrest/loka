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
      AshPhoenix.Form.for_action(Loka.Studios.Studio, :create_studio,
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
    <Layouts.app current_user={@current_user} flash={@flash}>
      <:nav>
        <.profile_tab_nav active={@current_path} />
      </:nav>

      <%= cond do %>
        <% @studio -> %>
          <.header>
            {@studio.name}
            <:subtitle>{gettext("Your studio is live.")}</:subtitle>
          </.header>
          <div class="px-4 py-10 sm:px-6 lg:px-8">
            <.link navigate={~p"/inventory/studio"}>{gettext("Manage studio")}</.link>
          </div>
        <% @show_form -> %>
          <.header>
            {gettext("Name your studio")}
            <:subtitle>{gettext("This can be changed at any time.")}</:subtitle>
          </.header>
          <div class="px-4 py-10 sm:px-6 lg:px-8 max-w-sm">
            <.form
              for={@form}
              phx-change="validate"
              phx-submit="save"
              class="mt-6 flex flex-col gap-4"
            >
              <.input field={@form[:name]} type="text" label={gettext("Studio name")} />
              <.button type="submit" class="btn btn-primary">{gettext("Create studio")}</.button>
            </.form>
          </div>
        <% true -> %>
          <div class="flex flex-col items-center justify-center py-24 gap-6 text-center max-w-sm mx-auto">
            <div class="bg-primary/10 text-primary rounded-2xl p-6">
              <.icon name="hero-building-storefront" class="size-14" />
            </div>

            <div class="flex flex-col gap-2">
              <h2 class="text-3xl font-bold tracking-tight">{gettext("Your studio awaits")}</h2>
              <p class="text-base-content/60 text-sm leading-relaxed">
                {gettext("Reach new customers, showcase your craft, and build something people love.")}
              </p>
            </div>

            <.button phx-click="show_form" class="btn btn-primary btn-wide mt-2">
              {gettext("Open your studio")}
            </.button>
          </div>
      <% end %>
    </Layouts.app>
    """
  end
end

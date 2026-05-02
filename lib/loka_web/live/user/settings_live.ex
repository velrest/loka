defmodule LokaWeb.User.SettingsLive do
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, uri, socket) do
    path = URI.parse(uri).path
    {:noreply, assign(socket, current_path: path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket}>
      <:nav>
        <.profile_tab_nav active={@current_path} />
      </:nav>

      <div class="px-4 py-10 sm:px-6 lg:px-8 max-w-lg">
        <div class="mb-8">
          <h1 class="text-2xl font-bold">{gettext("Einstellungen")}</h1>
        </div>

        <div class="card bg-base-100 border border-base-300 shadow shadow-black/30">
          <div class="card-body gap-0">
            <h3 class="font-semibold mb-4">{gettext("Konto")}</h3>

            <div class="flex justify-between items-center py-3 border-b border-base-200">
              <div>
                <p class="text-sm font-medium">{gettext("E-Mail-Adresse")}</p>
                <p class="text-xs text-base-content/50 mt-0.5">{@current_user.email}</p>
              </div>
              <%= if @current_user.confirmed_at do %>
                <span class="badge badge-success badge-sm">{gettext("Bestätigt")}</span>
              <% else %>
                <span class="badge badge-warning badge-sm">{gettext("Nicht bestätigt")}</span>
              <% end %>
            </div>

            <div class="flex justify-between items-center py-3">
              <p class="text-sm font-medium">{gettext("Passwort")}</p>
              <button class="btn btn-ghost btn-sm" disabled>{gettext("Ändern")}</button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end

defmodule LokaWeb.User.ProfileLive do
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
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
          <h1 class="text-2xl font-bold">{gettext("Profil")}</h1>
        </div>

        <div class="card bg-base-100 border border-base-300 shadow shadow-black/30">
          <div class="card-body gap-0">
            <h3 class="font-semibold mb-4">{gettext("Kontodaten")}</h3>

            <div class="flex justify-between items-center py-3 border-b border-base-200">
              <span class="text-sm text-base-content/50">{gettext("E-Mail")}</span>
              <span class="text-sm font-medium">{@current_user.email}</span>
            </div>

            <div class="flex justify-between items-center py-3">
              <span class="text-sm text-base-content/50">{gettext("Konto bestätigt")}</span>
              <%= if @current_user.confirmed_at do %>
                <span class="badge badge-success badge-sm">{gettext("Ja")}</span>
              <% else %>
                <span class="badge badge-warning badge-sm">{gettext("Nein")}</span>
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end

defmodule LokaWeb.User.StudioLive do
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash}>
      <:nav>
        <.profile_tab_nav active={@current_path} />
      </:nav>

      <div class="flex flex-col items-center justify-center py-20 gap-4">
        <p class="text-xl">{gettext("Add your studio!")}</p>
        <.button>{gettext("Continue")}</.button>
      </div>
    </Layouts.app>
    """
  end
end

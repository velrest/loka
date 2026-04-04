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

        <.button class="btn btn-primary btn-wide mt-2">{gettext("Open your studio")}</.button>
      </div>
    </Layouts.app>
    """
  end
end

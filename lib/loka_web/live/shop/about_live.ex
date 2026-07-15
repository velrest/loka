defmodule LokaWeb.Shop.AboutLive do
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash} socket={@socket}>
      <section class="rounded-box bg-base-200 mb-12 px-8 py-16 text-center">
        <div class="max-w-lg mx-auto">
          <span class="badge badge-primary badge-outline mb-4 tracking-widest uppercase text-xs px-3">
            {gettext("Handgefertigte Keramik")}
          </span>
          <h1 class="text-5xl font-bold leading-tight mb-4">
            {gettext("Von Hand gemacht,")}<br />{gettext("für immer geliebt")}
          </h1>
          <p class="text-base-content/60 text-lg">
            {gettext("Kleinserien-Töpferei von unabhängigen Studios.")}<br />{gettext(
              "Jedes Stück ein Unikat."
            )}
          </p>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

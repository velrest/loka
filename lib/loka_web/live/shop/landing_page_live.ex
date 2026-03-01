defmodule LokaWeb.Shop.LandingPageLive do
  use LokaWeb, :live_view

  # alias LokaWeb.Inventory

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash}>
      hello
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    # current_user = socket.assigns.current_user
    {:ok, socket}
  end
end

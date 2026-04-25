defmodule LokaWeb.Shop.CartWidgetLive do
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def render(assigns) do
    ~H"""
    Ok
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

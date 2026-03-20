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
    <Layouts.app current_user={@current_user} flash={@flash}>
      <.profile_tab_nav active={@current_path} />

      <.header>
        {gettext("Profile")}
        <:subtitle>{gettext("View your account details.")}</:subtitle>
      </.header>

      <.list>
        <:item title={gettext("User ID")}>
          {@current_user.id}
        </:item>
        <:item title={gettext("Email")}>
          {@current_user.email}
        </:item>
      </.list>
      <.link navigate={~p"/me/settings"}>{gettext("Settings")}</.link>
    </Layouts.app>
    """
  end
end

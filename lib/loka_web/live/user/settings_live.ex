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
    <Layouts.app current_user={@current_user} flash={@flash}>
      <:nav>
        <.profile_tab_nav active={@current_path} />
      </:nav>

      <.header>
        {gettext("My Settings")}
        <:subtitle>{gettext("Change account settings like passwords or email")}</:subtitle>
      </.header>

      <.list>
        <:item title={gettext("Account Confirmed")}>
          <%= if @current_user.confirmed_at do %>
            <span class="text-success">{gettext("Yes")}</span>
          <% else %>
            <span class="text-warning">{gettext("No")}</span>
          <% end %>
        </:item>
      </.list>
    </Layouts.app>
    """
  end
end

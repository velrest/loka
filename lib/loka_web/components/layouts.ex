defmodule LokaWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use LokaWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash} socket={@socket}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :current_user, Loka.Accounts.User, required: false
  attr :socket, Phoenix.LiveView.Socket, required: true

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true
  slot :inner_content, doc: "ash authentication uses inner_content as a slot"
  slot :nav, doc: "optional sub-navigation rendered below the header"

  def app(assigns) do
    ~H"""
    <header class="navbar px-4 sm:px-6 lg:px-8 sticky top-0 z-50">
      <.nav_bar current_user={@current_user} socket={@socket} />
    </header>

    <%= if @nav != [] do %>
      {render_slot(@nav)}
    <% end %>

    <main class="px-4 py-5 sm:px-6 lg:px-8">
      {render_slot(@inner_block)}
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("Keine Internetverbindung")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Verbindung wird hergestellt…")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Etwas ist schiefgelaufen!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Verbindung wird hergestellt…")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex items-center justify-center p-2 cursor-pointer w-1/3 opacity-75 hover:opacity-100"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4" />
      </button>

      <button
        class="flex items-center justify-center p-2 cursor-pointer w-1/3 opacity-75 hover:opacity-100"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4" />
      </button>

      <button
        class="flex items-center justify-center p-2 cursor-pointer w-1/3 opacity-75 hover:opacity-100"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4" />
      </button>
    </div>
    """
  end

  @doc """
  Renders the nav bar.
  ## Examples

      <.nav_bar current_user={@current_user} />
  """
  attr :current_user, Loka.Accounts.User, required: false
  attr :socket, Phoenix.LiveView.Socket, required: true

  def nav_bar(assigns) do
    ~H"""
    <div class="navbar bg-base-100 shadow-sm">
      <div class="flex-1">
        <.link class="btn btn-ghost text-xl" patch={~p"/"}>{gettext("keraloka")}</.link>
      </div>
      <div class="flex-none">
        <input type="text" placeholder={gettext("Suchen")} class="input input-bordered w-24 md:w-auto" />
        {live_render(@socket, LokaWeb.Shop.CartWidgetLive, id: "cart-widget")}
        <div class="dropdown dropdown-end">
          <div tabindex="0" role="button" class="btn btn-ghost btn-circle avatar">
            <div class="w-10 rounded-full">
              <.icon name="hero-user-circle" class="size-8" />
            </div>
          </div>
          <div
            tabindex="-1"
            class="menu menu-sm dropdown-content bg-base-100 rounded-box z-1 mt-3 w-52 p-2 shadow"
          >
            <ul>
              <%= if @current_user do %>
                <li><.link navigate={~p"/me"}>{gettext("Profil")}</.link></li>
                <li><.link navigate={~p"/inventory/studio"}>{gettext("Studio verwalten")}</.link></li>
                <li><.link patch={~p"/sign-out"}>{gettext("Abmelden")}</.link></li>
              <% else %>
                <li><.link patch={~p"/sign-in"}>{gettext("Anmelden")}</.link></li>
                <li><.link patch={~p"/register"}>{gettext("Registrieren")}</.link></li>
              <% end %>
            </ul>
            <.theme_toggle />
          </div>
        </div>
      </div>
    </div>
    """
  end
end

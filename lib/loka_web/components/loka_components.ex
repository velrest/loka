defmodule LokaWeb.LokaComponents do
  @moduledoc """
  Provides loka UI components.
  """
  use Phoenix.Component
  use Gettext, backend: LokaWeb.Gettext

  @doc """
  Renders a tab nav with links.

  ## Examples

      <.tab_nav>
        <:link title="Title">{@post.title}</:item>
        <:link title="Views">{@post.views}</:item>
      </.tab_nav>
  """
  attr :active_path, :string, default: "", doc: "The currently active path for marking tabs"
  attr :partial_match?, :boolean, default: false, doc: "Active if active_path matches partially"

  slot :item, required: true do
    attr :link, :string, required: true
  end

  def tab_nav(assigns) do
    ~H"""
    <div role="tablist" class="tabs tabs-box mx-4 sm:mx-6 lg:mx-8 my-2">
      <.link
        :for={item <- @item}
        role="tab"
        class={[
          "tab",
          if(
            if(@partial_match?,
              do: String.contains?(@active_path, item.link),
              else: item.link == @active_path
            ),
            do: "tab-active"
          )
        ]}
        navigate={item.link}
      >
        {render_slot(item)}
      </.link>
    </div>
    """
  end

  @doc """
  Renders the tab nav for /me.

  ## Examples

      <.profile_tab_nav active={@current_path} /
  """
  attr :active, :string, required: true

  def profile_tab_nav(assigns) do
    ~H"""
    <.tab_nav active_path={@active}>
      <:item link="/me">{gettext("Profile")}</:item>
      <:item link="/me/settings">{gettext("Settings")}</:item>
      <:item link="/me/studio">{gettext("Studio")}</:item>
    </.tab_nav>
    """
  end

  @doc """
  Renders the tab nav for /inventory.

  ## Examples

      <.inventory_tab_nav active={@current_path} /
  """
  attr :active, :string, required: true
  attr :partial_match?, :boolean, default: false, doc: "Active if active_path matches partially"

  def inventory_tab_nav(assigns) do
    ~H"""
    <.tab_nav active_path={@active} partial_match?={@partial_match?}>
      <:item link="/inventory/studio">{gettext("Studio")}</:item>
      <:item link="/inventory/items">{gettext("Items")}</:item>
    </.tab_nav>
    """
  end
end

defmodule LokaWeb.LokaComponents do
  @moduledoc """
  Provides loka UI components.
  """
  use Phoenix.Component
  use Gettext, backend: LokaWeb.Gettext
  use LokaWeb, :verified_routes

  alias Loka.Inventory

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
      <:item link="/me">{gettext("Profil")}</:item>
      <:item link="/me/settings">{gettext("Einstellungen")}</:item>
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
      <:item link="/inventory/items">{gettext("Artikel")}</:item>
    </.tab_nav>
    """
  end

  attr :stock, Inventory.Stock, required: true
  attr :current_user, :any, default: nil
  attr :show_studio, :boolean, default: true

  def stock_card(assigns) do
    ~H"""
    <div
      class="card bg-base-100 shadow-sm hover:shadow-lg transition-all duration-300 group overflow-hidden"
      data-item={@stock.id}
    >
      <div class="relative aspect-square bg-base-200">
        <img
          :if={@stock.item.images == []}
          src="/images/placeholder-pot.svg"
          alt=""
          class="w-full h-full object-cover"
        />

        <div
          :if={@stock.item.images != []}
          id={"slider-#{@stock.id}"}
          phx-hook="ImageSlider"
          class="relative w-full h-full overflow-hidden"
        >
          <div
            :for={{image, idx} <- Enum.with_index(@stock.item.images)}
            data-slide={idx}
            class={[
              "absolute inset-0 transition-opacity duration-300",
              if(idx == 0, do: "opacity-100", else: "opacity-0")
            ]}
          >
            <img
              src={image.path}
              alt={@stock.item.name}
              class="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            />
          </div>

          <div
            :if={length(@stock.item.images) > 1}
            class="absolute inset-x-2 top-1/2 -translate-y-1/2 flex justify-between z-10"
          >
            <button data-action="prev" class="btn btn-circle bg-base-100/80 backdrop-blur-sm border-0 shadow">
              <svg xmlns="http://www.w3.org/2000/svg" class="size-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
              </svg>
            </button>
            <button data-action="next" class="btn btn-circle bg-base-100/80 backdrop-blur-sm border-0 shadow">
              <svg xmlns="http://www.w3.org/2000/svg" class="size-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
              </svg>
            </button>
          </div>

          <div
            :if={length(@stock.item.images) > 1}
            class="absolute bottom-2 inset-x-0 flex justify-center gap-1 z-10"
          >
            <div
              :for={{_, idx} <- Enum.with_index(@stock.item.images)}
              data-dot={idx}
              class={[
                "size-1.5 rounded-full transition-all duration-300",
                if(idx == 0, do: "bg-white scale-125", else: "bg-white/40")
              ]}
            />
          </div>
        </div>
      </div>

      <div class="card-body p-4 gap-1">
        <.link
          :if={@show_studio}
          navigate={~p"/shop/studio/#{@stock.studio.id}"}
          class="text-xs font-medium text-primary uppercase tracking-widest truncate opacity-70 hover:opacity-100 transition-opacity"
        >
          {@stock.studio.name}
        </.link>
        <.link
          navigate={~p"/shop/item/#{@stock.item.id}"}
          class="font-semibold text-base leading-snug hover:text-primary transition-colors"
        >
          {@stock.item.name}
        </.link>
        <p class="text-sm text-base-content/50 line-clamp-2 leading-relaxed">
          {@stock.item.description}
        </p>
        <div class="flex items-center justify-between mt-4 pt-3 border-t border-base-200">
          <div>
            <span class="font-bold">{@stock.price}</span>
            <span class="text-xs text-base-content/40 ml-1">{gettext("/ Stück")}</span>
          </div>
          <.live_component
            module={LokaWeb.AddToCartComponent}
            id={"add-to-cart-#{@stock.id}"}
            stock={@stock}
            current_user={@current_user}
          />
        </div>
      </div>
    </div>
    """
  end
end

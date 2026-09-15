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

  @doc """
  Renders an 11px uppercase section label followed by a rule that fades out
  over its last 48px, with an optional right-aligned count.

  ## Examples

      <.section_header label={gettext("Jetzt verfügbar")} count="5 Stücke" />
  """
  attr :id, :string, default: nil
  attr :label, :string, required: true
  attr :count, :string, default: nil
  attr :class, :any, default: nil

  def section_header(assigns) do
    ~H"""
    <div id={@id} class={["flex items-baseline gap-4", @class]}>
      <h6 class="m-0 text-2xs font-semibold uppercase tracking-widest text-secondary whitespace-nowrap">
        {@label}
      </h6>
      <div class="rule-fade flex-1"></div>
      <span :if={@count} class="text-xs text-secondary whitespace-nowrap">{@count}</span>
    </div>
    """
  end

  @doc """
  Renders the "← Zurück zum ..." link used above shop detail pages.

  ## Examples

      <.back_link navigate={~p"/"}>{gettext("Zurück zum Markt")}</.back_link>
  """
  attr :navigate, :string, required: true
  slot :inner_block, required: true

  def back_link(assigns) do
    ~H"""
    <.link navigate={@navigate} class="link-back">
      ← {render_slot(@inner_block)}
    </.link>
    """
  end

  @doc """
  Renders a centered empty-state message, optionally with an icon and an
  action link/button below it.

  ## Examples

      <.empty_state message={gettext("Noch keine Artikel verfügbar.")} />

      <.empty_state message={gettext("Dein Warenkorb ist leer.")}>
        <:icon><svg>...</svg></:icon>
        <:action>
          <.link navigate={~p"/"} class="btn btn-primary btn-sm">{gettext("Zum Shop")}</.link>
        </:action>
      </.empty_state>
  """
  attr :message, :string, required: true
  slot :icon
  slot :action

  def empty_state(assigns) do
    ~H"""
    <div class="text-center py-24 text-base-content/40">
      {render_slot(@icon)}
      <p class={["text-lg", @action != [] && "mb-4"]}>{@message}</p>
      {render_slot(@action)}
    </div>
    """
  end

  @doc """
  Renders the first product image, or the placeholder artwork if there are
  none. `class` controls the outer box (size, radius, background).

  ## Examples

      <.item_thumbnail images={stock.item.images} alt={stock.item.name} class="size-16 rounded-lg bg-base-200" />
  """
  attr :images, :list, required: true
  attr :alt, :string, default: ""
  attr :class, :any, default: nil

  def item_thumbnail(assigns) do
    ~H"""
    <div class={["overflow-hidden", @class]}>
      <img
        :if={@images != []}
        src={List.first(@images).path}
        alt={@alt}
        class="w-full h-full object-cover"
      />
      <img
        :if={@images == []}
        src="/images/placeholder-pot.svg"
        alt=""
        class="w-full h-full object-cover"
      />
    </div>
    """
  end

  @doc """
  Renders a stock's photo, as an `ImageSlider`-hooked slider with prev/next
  arrows and dot indicators when there is more than one image.
  """
  attr :stock, Inventory.Stock, required: true

  def stock_photo_slider(assigns) do
    ~H"""
    <div class="relative aspect-square rounded-field overflow-hidden bg-base-300">
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
            "absolute inset-0 transition-opacity duration-150",
            if(idx == 0, do: "opacity-100", else: "opacity-0")
          ]}
        >
          <img src={image.path} alt={@stock.item.name} class="w-full h-full object-cover" />
        </div>

        <div
          :if={length(@stock.item.images) > 1}
          class="absolute inset-x-2 top-1/2 -translate-y-1/2 flex justify-between z-10"
        >
          <button
            data-action="prev"
            class="btn btn-circle bg-base-100/80 backdrop-blur-sm border-0 shadow"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="size-5" viewBox="0 0 20 20" fill="currentColor">
              <path
                fill-rule="evenodd"
                d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z"
                clip-rule="evenodd"
              />
            </svg>
          </button>
          <button
            data-action="next"
            class="btn btn-circle bg-base-100/80 backdrop-blur-sm border-0 shadow"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="size-5" viewBox="0 0 20 20" fill="currentColor">
              <path
                fill-rule="evenodd"
                d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                clip-rule="evenodd"
              />
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
              "size-1.5 rounded-full transition-all duration-150",
              if(idx == 0, do: "bg-white scale-125", else: "bg-white/40")
            ]}
          />
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders the item detail page's photo gallery: a thumbnail rail plus the
  main photo, wired to the `ImageSlider` hook. Rendered as siblings inside
  the caller's own grid (it does not own the grid layout).
  """
  attr :images, :list, required: true
  attr :name, :string, required: true

  def item_photos(assigns) do
    ~H"""
    <div :if={@images != []} class="flex lg:flex-col gap-2.5 order-2 lg:order-1">
      <button
        :for={{image, idx} <- Enum.with_index(@images)}
        type="button"
        data-thumb={idx}
        class={[
          "relative aspect-square w-16 lg:w-auto rounded-field overflow-hidden bg-base-300 shrink-0",
          if(idx == 0, do: "shadow-[inset_0_0_0_1px_var(--clay-accent-700)]")
        ]}
      >
        <img src={image.path} alt="" class="w-full h-full object-cover" />
      </button>
    </div>

    <div class="relative aspect-square rounded-box overflow-hidden bg-base-300 order-1 lg:order-2">
      <img
        :if={@images == []}
        src="/images/placeholder-pot.svg"
        alt=""
        class="w-full h-full object-cover"
      />
      <div
        :for={{image, idx} <- Enum.with_index(@images)}
        data-slide={idx}
        class={[
          "absolute inset-0 transition-opacity duration-150",
          if(idx == 0, do: "opacity-100", else: "opacity-0")
        ]}
      >
        <img src={image.path} alt={@name} class="w-full h-full object-cover" />
      </div>
    </div>
    """
  end

  attr :stock, Inventory.Stock, required: true
  attr :current_user, :any, default: nil
  attr :show_studio, :boolean, default: true

  def stock_card(assigns) do
    ~H"""
    <div class="flex flex-col gap-2.5" data-item={@stock.id}>
      <.stock_photo_slider stock={@stock} />

      <div class="flex items-baseline justify-between gap-2.5">
        <.link
          navigate={~p"/shop/item/#{@stock.item.id}"}
          class="text-xl tracking-snug hover:text-primary transition-colors duration-150"
        >
          {@stock.item.name}
        </.link>
        <span class="text-15 whitespace-nowrap text-[color:var(--clay-neutral-200)]">
          {@stock.price}
        </span>
      </div>

      <div class="flex items-baseline justify-between gap-2.5 -mt-1">
        <.link
          :if={@show_studio}
          navigate={~p"/shop/studio/#{@stock.studio.id}"}
          class="text-13 text-accent hover:opacity-80 transition-opacity duration-150"
        >
          {@stock.studio.name} · {@stock.studio.city}
        </.link>
        <span class="text-2xs whitespace-nowrap text-secondary ml-auto">
          {stock_line(@stock)}
        </span>
      </div>

      <p class="mt-0.5 mb-2 text-13 leading-normal text-secondary line-clamp-2">
        {@stock.item.description}
      </p>

      <.live_component
        module={LokaWeb.AddToCartComponent}
        id={"add-to-cart-#{@stock.id}"}
        stock={@stock}
        current_user={@current_user}
        class="btn-primary btn-block mt-auto"
      />
    </div>
    """
  end

  defp stock_line(%{quantity: quantity}) do
    gettext("%{count} verfügbar", count: quantity)
  end
end

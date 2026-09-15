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
      <h6 class="m-0 text-[11px] font-semibold uppercase tracking-[0.1em] text-secondary whitespace-nowrap">
        {@label}
      </h6>
      <div class="rule-fade flex-1"></div>
      <span :if={@count} class="text-xs text-secondary whitespace-nowrap">{@count}</span>
    </div>
    """
  end

  attr :stock, Inventory.Stock, required: true
  attr :current_user, :any, default: nil
  attr :show_studio, :boolean, default: true

  def stock_card(assigns) do
    ~H"""
    <div class="flex flex-col gap-2.5" data-item={@stock.id}>
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
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="size-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
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
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="size-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
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

      <div class="flex items-baseline justify-between gap-2.5">
        <.link
          navigate={~p"/shop/item/#{@stock.item.id}"}
          class="text-xl tracking-[-0.02em] hover:text-primary transition-colors duration-150"
        >
          {@stock.item.name}
        </.link>
        <span class="text-[15px] whitespace-nowrap text-[color:var(--clay-neutral-200)]">
          {@stock.price}
        </span>
      </div>

      <div class="flex items-baseline justify-between gap-2.5 -mt-1">
        <.link
          :if={@show_studio}
          navigate={~p"/shop/studio/#{@stock.studio.id}"}
          class="text-[13px] text-accent hover:opacity-80 transition-opacity duration-150"
        >
          {@stock.studio.name} · {@stock.studio.city}
        </.link>
        <span class="text-[11px] whitespace-nowrap text-secondary ml-auto">
          {stock_line(@stock)}
        </span>
      </div>

      <p class="mt-0.5 mb-2 text-[13px] leading-[1.5] text-secondary line-clamp-2">
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

  @low_stock_threshold 5

  defp stock_line(%{quantity: quantity}) when quantity <= @low_stock_threshold do
    gettext("nur noch %{count}", count: quantity)
  end

  defp stock_line(%{quantity: quantity}) do
    gettext("%{count} verfügbar", count: quantity)
  end
end

defmodule LokaWeb.Shop.LandingPageLive do
  alias Loka.Inventory
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
            {gettext("Kleinserien-Töpferei von unabhängigen Studios.")}<br />{gettext("Jedes Stück ein Unikat.")}
          </p>
        </div>
      </section>

      <div class="flex items-center gap-3 mb-8">
        <h2 class="text-xs font-semibold uppercase tracking-widest text-base-content/50 whitespace-nowrap">
          {gettext("Jetzt verfügbar")}
        </h2>
        <div class="flex-1 border-t border-base-300"></div>
        <span class="text-xs text-base-content/40 whitespace-nowrap">
          {length(@stock)} {ngettext("Stück", "Stücke", length(@stock))}
        </span>
      </div>

      <div :if={@stock == []} class="text-center py-24 text-base-content/40">
        <p class="text-lg">{gettext("Noch keine Artikel verfügbar.")}</p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 pb-16">
        <.stock_card :for={stock <- @stock} stock={stock} current_user={@current_user} />
      </div>
    </Layouts.app>

    <script :type={Phoenix.LiveView.ColocatedHook} name=".ImageSlider">
      export default {
        mounted() {
          this.current = 0
          this.slides = Array.from(this.el.querySelectorAll('[data-slide]'))
          this.dots = Array.from(this.el.querySelectorAll('[data-dot]'))

          this.el.querySelector('[data-action="prev"]')?.addEventListener('click', e => {
            e.stopPropagation()
            this.show((this.current - 1 + this.slides.length) % this.slides.length)
          })
          this.el.querySelector('[data-action="next"]')?.addEventListener('click', e => {
            e.stopPropagation()
            this.show((this.current + 1) % this.slides.length)
          })
        },
        show(i) {
          this.slides[this.current].classList.remove('opacity-100')
          this.slides[this.current].classList.add('opacity-0')
          if (this.dots[this.current]) {
            this.dots[this.current].classList.remove('bg-white', 'scale-125')
            this.dots[this.current].classList.add('bg-white/40')
          }
          this.current = i
          this.slides[this.current].classList.remove('opacity-0')
          this.slides[this.current].classList.add('opacity-100')
          if (this.dots[this.current]) {
            this.dots[this.current].classList.remove('bg-white/40')
            this.dots[this.current].classList.add('bg-white', 'scale-125')
          }
        }
      }
    </script>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    stock = Inventory.list_all_stock!(load: [:studio, item: :images])
    {:ok, assign(socket, stock: stock)}
  end

  attr :stock, Inventory.Stock, required: true
  attr :current_user, :any, default: nil

  defp stock_card(assigns) do
    ~H"""
    <div
      class="card bg-base-100 shadow-sm hover:shadow-lg transition-all duration-300 group overflow-hidden"
      data-item={@stock.id}
    >
      <%!-- Image area --%>
      <div class="relative aspect-square bg-base-200">
        <%!-- Placeholder when no images --%>
        <img
          :if={@stock.item.images == []}
          src="/images/placeholder-pot.svg"
          alt=""
          class="w-full h-full object-cover"
        />

        <%!-- Slider --%>
        <div
          :if={@stock.item.images != []}
          id={"slider-#{@stock.id}"}
          phx-hook=".ImageSlider"
          class="relative w-full h-full overflow-hidden"
        >
          <%!-- Slides — stacked, crossfade via opacity --%>
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

          <%!-- Prev / Next --%>
          <div
            :if={length(@stock.item.images) > 1}
            class="absolute inset-x-2 top-1/2 -translate-y-1/2 flex justify-between z-10"
          >
            <button
              data-action="prev"
              class="btn btn-circle bg-base-100/80 backdrop-blur-sm border-0 shadow"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="size-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M12.707 5.293a1 1 0 010 1.414L9.414 10l3.293 3.293a1 1 0 01-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
              </svg>
            </button>
            <button
              data-action="next"
              class="btn btn-circle bg-base-100/80 backdrop-blur-sm border-0 shadow"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="size-5" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd" />
              </svg>
            </button>
          </div>

          <%!-- Dot indicators --%>
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

      <%!-- Card body --%>
      <div class="card-body p-4 gap-1">
        <p class="text-xs font-medium text-primary uppercase tracking-widest truncate opacity-70">
          {@stock.studio.name}
        </p>
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
            module={LokaWeb.Shop.AddToCartLiveComponent}
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

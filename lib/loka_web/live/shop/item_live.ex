defmodule LokaWeb.Shop.ItemLive do
  alias Loka.Inventory
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_optional}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash}>
      <div class="px-4 py-10 sm:px-6 lg:px-8 max-w-2xl">
        <.header>
          {@item.name}
          <:subtitle>
            <.link navigate={~p"/"} class="text-sm text-base-content/60 hover:underline">
              &larr; {gettext("Back to shop")}
            </.link>
          </:subtitle>
        </.header>

        <div class="mt-6 flex flex-col gap-6">
          <div :if={@item.images != []} class="carousel w-full rounded-box">
            <div
              :for={{image, index} <- Enum.with_index(@item.images)}
              id={"slide_#{@item.id}_#{index}"}
              class="carousel-item relative w-full"
            >
              <img src={image.path} alt={@item.name} class="w-full object-cover" />
              <div class="absolute left-5 right-5 top-1/2 flex -translate-y-1/2 transform justify-between">
                <a
                  href={"#slide_#{@item.id}_#{if index == 0, do: length(@item.images) - 1, else: index - 1}"}
                  class="btn btn-circle"
                >
                  &#10094;
                </a>
                <a
                  href={"#slide_#{@item.id}_#{if index == length(@item.images) - 1, do: 0, else: index + 1}"}
                  class="btn btn-circle"
                >
                  &#10095;
                </a>
              </div>
            </div>
          </div>

          <p data-testid="item-description" class="text-base-content/80">{@item.description}</p>

          <div :for={stock <- @item.stock} class="card bg-base-100 shadow-sm">
            <div class="card-body flex-row items-center justify-between">
              <span data-testid="item-price" class="text-xl font-semibold">{stock.price}</span>
              <button class="btn btn-primary">{gettext("In den Warenkorb")}</button>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case Inventory.get_item(id) do
      {:ok, nil} ->
        {:ok,
         socket
         |> put_flash(:error, gettext("Item not found."))
         |> push_navigate(to: ~p"/")}

      {:error, error} ->
        {:ok,
         socket
         |> put_flash(:error, gettext("Item not found."))
         |> push_navigate(to: ~p"/")}

      {:ok, item} ->
        {:ok, assign(socket, item: item)}
    end
  end
end

defmodule LokaWeb.AddressInputComponent do
  use LokaWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, suggestions: [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-3 gap-3" id={@id}>
      <.input field={@postal_code_field} type="text" label={gettext("PLZ")} />

      <div class="col-span-2 fieldset mb-2 relative">
        <label for={@city_field.id}>
          <span class="label mb-1">{gettext("Ort")}</span>
          <input
            type="text"
            name={@city_field.name}
            id={@city_field.id}
            value={Phoenix.HTML.Form.normalize_value("text", @city_field.value)}
            phx-keyup="search"
            phx-debounce="200"
            phx-target={@myself}
            autocomplete="off"
            class="w-full input"
          />
        </label>
        <ul
          :if={@suggestions != []}
          class="absolute z-20 w-full mt-1 bg-base-100 border border-base-300 rounded-box shadow-lg overflow-hidden"
        >
          <li
            :for={s <- @suggestions}
            phx-click="select"
            phx-value-city={s.city}
            phx-value-zip={s.zip}
            phx-target={@myself}
            class="flex items-center gap-3 px-4 py-2 hover:bg-base-200 cursor-pointer text-sm"
          >
            <span class="font-mono text-xs text-base-content/40 w-10 shrink-0">{s.zip}</span>
            {s.city}
          </li>
        </ul>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("search", %{"value" => value}, socket) do
    {:noreply, assign(socket, suggestions: Loka.Address.Localities.search(value))}
  end

  def handle_event("select", %{"city" => city, "zip" => zip}, socket) do
    send(self(), {:city_selected, %{city: city, zip: zip}})
    {:noreply, assign(socket, suggestions: [])}
  end
end

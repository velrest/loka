defmodule LokaWeb.StudioMapComponent do
  use LokaWeb, :live_component

  @impl true
  def update(%{studios: studios} = assigns, socket) do
    markers =
      studios
      |> Enum.filter(&(&1.latitude && &1.longitude))
      |> Enum.map(
        &%{
          id: &1.id,
          lat: &1.latitude,
          lng: &1.longitude,
          name: &1.name,
          city: &1.city,
          description: &1.description,
          logo_path: &1.logo_path
        }
      )

    {:ok,
     socket
     |> assign(assigns)
     |> push_event("set_markers", %{markers: markers})}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="relative mb-12" style="z-index: 0">
      <div id={"#{@id}-canvas"} phx-hook=".StudioMap" class="h-80 w-full rounded-box" />

      <script :type={Phoenix.LiveView.ColocatedHook} name=".StudioMap">
        import L from "leaflet"

        export default {
          _markers: [],
          _map: null,
          _userLocated: false,
          mounted() {
            this._map = L.map(this.el).setView([46.8182, 8.2275], 8)
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
              attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
              maxZoom: 19
            }).addTo(this._map)

            if (navigator.geolocation) {
              let watchId = navigator.geolocation.watchPosition(
                pos => {
                  navigator.geolocation.clearWatch(watchId)
                  this._userLocated = true
                  this._map.flyTo([pos.coords.latitude, pos.coords.longitude], 11)
                },
                () => {},
                { maximumAge: 300000, enableHighAccuracy: false, timeout: 10000 }
              )
            }

            this.handleEvent("set_markers", ({markers}) => this._setMarkers(markers))

            const emit = () => {
              const b = this._map.getBounds()
              this.pushEvent("bounds_changed", {
                north: b.getNorth(),
                south: b.getSouth(),
                east: b.getEast(),
                west: b.getWest(),
                zoom: this._map.getZoom()
              })
            }
            this._map.on('moveend', emit)
            this._map.on('zoomend', emit)
          },
          updated() {
            if (this._map) this._map.invalidateSize()
          },
          _setMarkers(markers) {
            this._markers.forEach(m => m.remove())
            this._markers = []
            const latlngs = []
            markers.forEach(({lat, lng, name, city, description, logo_path}) => {
              const logo = logo_path
                ? `<img src="${logo_path}" class="w-12 h-12 rounded-lg object-cover shrink-0" />`
                : ''
              const desc = description
                ? `<p class="text-xs text-gray-500 mt-1 line-clamp-2">${description}</p>`
                : ''
              const popup = `
                <div class="flex items-start gap-2 min-w-[160px]">
                  ${logo}
                  <div>
                    <p class="font-semibold text-sm leading-tight">${name}</p>
                    <p class="text-xs text-gray-400">${city}</p>
                    ${desc}
                  </div>
                </div>`
              const m = L.marker([lat, lng])
                .bindPopup(popup, {maxWidth: 240})
                .addTo(this._map)
              this._markers.push(m)
              latlngs.push([lat, lng])
            })

            if (latlngs.length > 0 && !this._userLocated) {
              this._map.fitBounds(latlngs, {padding: [40, 40], maxZoom: 12})
            }
          }
        }
      </script>
    </div>
    """
  end
end

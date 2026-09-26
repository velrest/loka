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
     |> assign_new(:snapshot, fn -> false end)
     |> push_event("set_markers", %{markers: markers})}
  end

  @doc """
  Renders the studio map.

  Two variants: the default full map (draggable, zoomable, filters the
  market list by viewport via `bounds_changed`) and `snapshot={true}`, a
  small non-interactive map centered on a single studio's location.
  """
  attr :id, :string, required: true
  attr :studios, :list, required: true
  attr :snapshot, :boolean, default: false
  attr :thunderforest_key, :string, default: nil

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="relative" style="z-index: 0">
      <div
        id={"#{@id}-canvas"}
        phx-hook=".StudioMap"
        data-snapshot={to_string(@snapshot)}
        data-tf-key={@thunderforest_key}
        class={[
          "w-full bg-base-300",
          if(@snapshot, do: "h-[150px] rounded-box", else: "h-[400px] rounded-t-box")
        ]}
      />

      <script :type={Phoenix.LiveView.ColocatedHook} name=".StudioMap">
        import L from "leaflet"

        function glowIcon(size) {
          return L.divIcon({
            className: "",
            html: `<span style="display:block;width:100%;height:100%;border-radius:50%;background:var(--color-primary);box-shadow:0 0 0 6px color-mix(in srgb, var(--color-primary) 22%, transparent)"></span>`,
            iconSize: [size, size],
            iconAnchor: [size / 2, size / 2],
            popupAnchor: [0, -size / 2]
          })
        }

        export default {
          _markers: [],
          _map: null,
          _userLocated: false,
          mounted() {
            const snapshot = this.el.dataset.snapshot === "true"
            this._snapshot = snapshot

            this._map = L.map(this.el, {
              zoomControl: !snapshot,
              dragging: !snapshot,
              scrollWheelZoom: !snapshot,
              doubleClickZoom: !snapshot,
              boxZoom: !snapshot,
              keyboard: !snapshot,
              touchZoom: !snapshot,
              attributionControl: !snapshot
            }).setView([46.8182, 8.2275], 8)

            this._osmLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
              attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
              maxZoom: 19
            }).addTo(this._map)

            const tfKey = this.el.dataset.tfKey
            if (tfKey) {
              this._pioneerLayer = L.tileLayer(
                `https://{s}.tile.thunderforest.com/pioneer/{z}/{x}/{y}{r}.png?apikey=${tfKey}`,
                {
                  attribution: '© <a href="https://www.thunderforest.com/">Thunderforest</a>, © <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
                  maxZoom: 22
                }
              )
              this._pioneerHandler = () => {
                if (this._map.hasLayer(this._pioneerLayer)) {
                  this._map.removeLayer(this._pioneerLayer)
                  this._map.addLayer(this._osmLayer)
                } else {
                  this._map.removeLayer(this._osmLayer)
                  this._map.addLayer(this._pioneerLayer)
                }
              }
              window.addEventListener("loka:toggle-pioneer", this._pioneerHandler)
            }

            if (!snapshot && navigator.geolocation) {
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

            if (!snapshot) {
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
            }
          },
          updated() {
            if (this._map) this._map.invalidateSize()
          },
          _setMarkers(markers) {
            const snapshot = this._snapshot
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
              const marker = L.marker([lat, lng], {
                icon: glowIcon(snapshot ? 12 : 14),
                interactive: !snapshot
              })
              if (!snapshot) marker.bindPopup(popup, {maxWidth: 240})
              marker.addTo(this._map)
              this._markers.push(marker)
              latlngs.push([lat, lng])
            })

            if (latlngs.length > 0) {
              if (snapshot) {
                this._map.setView(latlngs[0], 13)
              } else if (!this._userLocated) {
                this._map.fitBounds(latlngs, {padding: [40, 40], maxZoom: 12})
              }
            }
          }
        }
      </script>
    </div>
    """
  end
end

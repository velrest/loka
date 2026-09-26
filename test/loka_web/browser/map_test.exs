defmodule LokaWeb.Browser.MapTest do
  @moduledoc """
  Browser test for the market map's hook: zooming the Leaflet map sends the
  visible area to the server, which filters the items below it. The filtering
  itself is covered in LokaWeb.Shop.MarketLiveTest.
  """

  use PhoenixTest.Playwright.Case, async: true
  use LokaWeb, :verified_routes

  # Skip with `mix test --exclude playwright`
  @moduletag :playwright

  alias Loka.Support.{InventoryHelpers, UserHelpers}

  setup do
    # The map opens on central Switzerland (46.82 / 8.23). Zürich (~60 km) and
    # Geneva (~180 km) are outside the view from zoom 10 on; Sarnen is near
    # the centre
    studio_items =
      for {name, city, postal_code} <- [
            {"Sarnen Krug", "Sarnen", "6060"},
            {"Zürich Mug", "Zürich", "8001"},
            {"Geneva Bowl", "Genève", "1201"}
          ],
          into: %{} do
        %{owner: owner} =
          UserHelpers.create_studio_owner(%{
            name: "#{city} Studio",
            city: city,
            postal_code: postal_code
          })

        {city, InventoryHelpers.create_item(owner, %{name: name})}
      end

    %{items: studio_items}
  end

  # Leaflet ignores zoom clicks during its zoom animation (~250ms), so give
  # each one time to finish
  defp zoom_in(conn) do
    conn
    |> click(".leaflet-control-zoom-in")
    |> evaluate("new Promise(resolve => setTimeout(resolve, 400))")
  end

  # Leaflet pans a little on its own while the page settles (invalidateSize),
  # so the exact view varies between runs. This test only checks that the
  # hook sends the view and the list follows; which studios are inside a
  # given area is tested with fixed coordinates in LokaWeb.Shop.MarketLiveTest.
  test "zooming the map in filters the items to the visible area", %{conn: conn, items: items} do
    conn
    |> visit(~p"/")
    |> assert_has("[data-phx-main].phx-connected")
    |> assert_has("[data-item]", count: 3)
    # Zoom 8 → 10, where filtering starts
    |> zoom_in()
    |> zoom_in()
    |> refute_has("[data-item='#{items["Zürich"].id}']")
    |> refute_has("[data-item='#{items["Genève"].id}']")
  end
end

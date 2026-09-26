defmodule LokaWeb.Shop.MarketLiveTest do
  use LokaWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Loka.Support.{InventoryHelpers, UserHelpers}

  # What the map hook sends after it's moved or zoomed. Zürich is around
  # 47.37 / 8.54, Geneva around 46.20 / 6.14.
  @around_zurich %{"north" => 47.5, "south" => 47.2, "east" => 8.8, "west" => 8.3}

  setup do
    %{owner: zurich_owner} = UserHelpers.create_studio_owner()

    %{owner: geneva_owner} =
      UserHelpers.create_studio_owner(%{name: "Atelier Lac", city: "Genève", postal_code: "1201"})

    # Unknown postal code, so the studio has no coordinates
    %{owner: nowhere_owner} =
      UserHelpers.create_studio_owner(%{name: "Nowhere", city: "Nirgendwo", postal_code: "9999"})

    %{
      zurich_item: InventoryHelpers.create_item(zurich_owner, %{name: "Zürich Mug"}),
      geneva_item: InventoryHelpers.create_item(geneva_owner, %{name: "Geneva Bowl"}),
      nowhere_item: InventoryHelpers.create_item(nowhere_owner, %{name: "Nowhere Vase"})
    }
  end

  defp move_map(view, bounds, zoom) do
    render_hook(view, "bounds_changed", Map.put(bounds, "zoom", zoom))
  end

  test "shows every item before the map is moved", context do
    {:ok, view, _html} = live(context.conn, ~p"/")

    for item <- [context.zurich_item, context.geneva_item, context.nowhere_item] do
      assert has_element?(view, "[data-item='#{item.id}']")
    end
  end

  test "zoomed in, only items of studios inside the map area are shown", context do
    {:ok, view, _html} = live(context.conn, ~p"/")
    move_map(view, @around_zurich, 11)

    assert has_element?(view, "[data-item='#{context.zurich_item.id}']")
    refute has_element?(view, "[data-item='#{context.geneva_item.id}']")
    assert render(view) =~ "1 Stück · 1 Studio im Kartenausschnitt"
  end

  test "zoomed in, studios without coordinates are left out", context do
    {:ok, view, _html} = live(context.conn, ~p"/")
    move_map(view, @around_zurich, 11)

    refute has_element?(view, "[data-item='#{context.nowhere_item.id}']")
  end

  test "below zoom 10 nothing is filtered, even if the area doesn't contain every studio",
       context do
    {:ok, view, _html} = live(context.conn, ~p"/")
    move_map(view, @around_zurich, 9)

    assert has_element?(view, "[data-item='#{context.geneva_item.id}']")
    assert has_element?(view, "[data-item='#{context.nowhere_item.id}']")
  end

  test "zooming back out shows every item again", context do
    {:ok, view, _html} = live(context.conn, ~p"/")
    move_map(view, @around_zurich, 11)
    move_map(view, @around_zurich, 8)

    assert has_element?(view, "[data-item='#{context.geneva_item.id}']")
    assert has_element?(view, "[data-item='#{context.nowhere_item.id}']")
  end

  test "an area without studios shows the empty state", context do
    {:ok, view, _html} = live(context.conn, ~p"/")
    move_map(view, %{"north" => 46.0, "south" => 45.9, "east" => 9.0, "west" => 8.9}, 12)

    assert has_element?(view, "p", "Noch keine Artikel verfügbar.")
  end
end

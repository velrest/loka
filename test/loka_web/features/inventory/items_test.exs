defmodule LokaWeb.Features.Inventory.ItemsTest do
  use LokaWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Loka.Support.{InventoryHelpers, UserHelpers}

  setup %{conn: conn} do
    %{owner: user} = UserHelpers.create_studio_owner()
    conn = log_in_user(conn, user)
    %{user: user, conn: conn}
  end

  defp log_in_user(conn, user) do
    {:ok, token, _claims} = AshAuthentication.Jwt.token_for_user(user)
    Plug.Test.init_test_session(conn, %{"user_token" => token})
  end

  describe "/inventory/items/new (create mode)" do
    test "renders creation form with item and stock fields", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/inventory/items/new")
      assert has_element?(view, "h1", "Neuer Artikel")
      assert has_element?(view, "input[name='form[name]']")
      assert has_element?(view, "textarea[name='form[description]']")
      assert has_element?(view, "input[name='form[stock][price]']")
      assert has_element?(view, "input[name='form[stock][quantity]']")
    end

    test "back link points to /inventory/items", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/inventory/items/new")
      assert has_element?(view, "a", "← Zurück zu Artikeln")
    end

    test "submitting the form with an image creates an item for the user's studio",
         %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/inventory/items/new")

      upload =
        file_input(view, "form", :images, [
          %{
            last_modified: 1_594_171_879_000,
            name: "test.jpg",
            content: :crypto.strong_rand_bytes(10),
            type: "image/jpeg"
          }
        ])

      render_upload(upload, "test.jpg")

      view
      |> form("form",
        form: %{
          name: "Test Pot",
          description: "A fine pot",
          stock: %{price: "CHF 50", quantity: "2"}
        }
      )
      |> render_submit()

      assert_redirected(view, ~p"/inventory/items")

      [item] = Loka.Inventory.list_all_items!()
      assert item.name == "Test Pot"
      assert item.studio_id == user.studio.id
      assert item.stock.quantity == 2
      assert item.stock.price == Money.new(:CHF, 50)
    end
  end

  describe "/inventory/items/:id (edit mode)" do
    setup %{user: user} do
      item =
        InventoryHelpers.create_item(user, %{
          name: "Bowl",
          description: "Ceramic bowl",
          stock: %{quantity: 3, price: Money.new(:CHF, 150)}
        })

      %{item: item}
    end

    test "renders item and stock forms", %{conn: conn, item: item} do
      {:ok, view, _html} = live(conn, ~p"/inventory/items/#{item.id}")
      assert has_element?(view, "h1", "Bowl")
      assert has_element?(view, "input[name='item[name]'][value='Bowl']")
      assert has_element?(view, "input[name='stock[price]']")
    end

    test "saving item details updates the item", %{conn: conn, item: item} do
      {:ok, view, _html} = live(conn, ~p"/inventory/items/#{item.id}")

      view
      |> form("form[phx-submit='save_item']", item: %{name: "Ceramic Bowl"})
      |> render_submit()

      assert has_element?(view, "input[name='item[name]'][value='Ceramic Bowl']")
    end

    test "uploading an image in edit mode attaches it to the item", %{conn: conn, item: item} do
      {:ok, view, _html} = live(conn, ~p"/inventory/items/#{item.id}")

      upload =
        file_input(view, "#image-upload-card", :images, [
          %{
            last_modified: 1_594_171_879_000,
            name: "bowl.jpg",
            content: :crypto.strong_rand_bytes(10),
            type: "image/jpeg"
          }
        ])

      render_upload(upload, "bowl.jpg")

      view
      |> form("form[phx-submit='save_item']", item: %{name: "Bowl"})
      |> render_submit()

      images = Loka.Inventory.list_item_images!(item.id)
      assert length(images) == 1
      assert hd(images).filename =~ ".jpg"
    end

    test "saving pricing and stock updates price and quantity", %{conn: conn, item: item} do
      {:ok, view, _html} = live(conn, ~p"/inventory/items/#{item.id}")

      view
      |> form("form[phx-submit='save_stock']", stock: %{price: "CHF 200", quantity: "10"})
      |> render_submit()

      assert has_element?(view, "input[name='stock[quantity]'][value='10']")
    end
  end

  describe "/inventory/items/:id (selling)" do
    test "taking an item off sale archives its stock", %{conn: conn, user: user} do
      item = InventoryHelpers.create_item(user)

      {:ok, view, _html} = live(conn, ~p"/inventory/items/#{item.id}")
      view |> element("button[phx-click='unlist']") |> render_click()

      assert has_element?(view, "button", "Zum Verkauf anbieten")
      refute has_element?(view, "button[phx-click='unlist']")
      assert Ash.load!(item, :stock).stock == nil
    end

    test "an item without stock can be put on sale", %{conn: conn, user: user} do
      item = InventoryHelpers.create_item(user, %{stock: nil})

      {:ok, view, _html} = live(conn, ~p"/inventory/items/#{item.id}")
      assert has_element?(view, "button", "Zum Verkauf anbieten")

      view
      |> form("form[phx-submit='save_stock']", stock: %{price: "CHF 75", quantity: "4"})
      |> render_submit()

      item = Ash.load!(item, :stock)
      assert item.stock.quantity == 4
      assert item.stock.price == Money.new(:CHF, 75)
      assert has_element?(view, "button[phx-click='unlist']")
    end

    test "archiving the item archives it and its stock", %{conn: conn, user: user} do
      item = InventoryHelpers.create_item(user)

      {:ok, view, _html} = live(conn, ~p"/inventory/items/#{item.id}")
      render_click(view, "delete", %{})

      assert_redirected(view, ~p"/inventory/items")
      assert {:ok, nil} = Loka.Inventory.get_item(item.id)
      assert {:error, %Ash.Error.Invalid{}} = Ash.get(Loka.Inventory.Stock, item.stock.id)
    end

    test "another studio's item redirects to the list", %{conn: conn} do
      %{owner: other_owner} = UserHelpers.create_studio_owner()
      item = InventoryHelpers.create_item(other_owner)

      assert {:error, {:live_redirect, %{to: "/inventory/items"}}} =
               live(conn, ~p"/inventory/items/#{item.id}")
    end
  end

  describe "/inventory/items/:id image removal" do
    setup %{user: user} do
      item =
        InventoryHelpers.create_item(user, %{
          name: "Vase",
          description: "Glass vase",
          stock: %{quantity: 1, price: Money.new(:CHF, 80)}
        })

      %{item: item}
    end

    defp create_test_image(item_id, actor) do
      {:ok, tmp} = Plug.Upload.random_file("test")
      File.write!(tmp, "fake image")
      file = %Plug.Upload{path: tmp, filename: "test.jpg", content_type: "image/jpeg"}
      Loka.Inventory.create_image!(item_id, file, %{}, actor: actor)
    end

    test "remove button is hidden when only one image exists", %{
      conn: conn,
      item: item,
      user: user
    } do
      create_test_image(item.id, user)

      {:ok, view, _html} = live(conn, ~p"/inventory/items/#{item.id}")

      refute has_element?(view, "button[phx-click='remove_image']")
    end

    test "remove button is shown when multiple images exist", %{
      conn: conn,
      item: item,
      user: user
    } do
      create_test_image(item.id, user)
      create_test_image(item.id, user)

      {:ok, view, _html} = live(conn, ~p"/inventory/items/#{item.id}")

      assert has_element?(view, "button[phx-click='remove_image']")
    end

    test "removing the last image via event returns an error flash", %{
      conn: conn,
      item: item,
      user: user
    } do
      image = create_test_image(item.id, user)

      {:ok, view, _html} = live(conn, ~p"/inventory/items/#{item.id}")

      render_click(view, "remove_image", %{"id" => image.id})

      assert has_element?(view, "[role='alert']", "Mindestens ein Bild ist erforderlich.")
    end

    test "can remove an image when multiple images exist", %{conn: conn, item: item, user: user} do
      image = create_test_image(item.id, user)
      create_test_image(item.id, user)

      {:ok, view, _html} = live(conn, ~p"/inventory/items/#{item.id}")

      render_click(view, "remove_image", %{"id" => image.id})

      images = Loka.Inventory.list_item_images!(item.id)
      assert length(images) == 1
    end
  end

  describe "/inventory/items list" do
    test "renders the items table header", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/inventory/items")
      assert has_element?(view, "h1", "Artikel")
    end

    test "'Neuer Artikel' button navigates to /inventory/items/new", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/inventory/items")

      {:error, {:live_redirect, %{to: path}}} =
        view |> element(".flex.justify-between a", "Neuer Artikel") |> render_click()

      assert path == ~p"/inventory/items/new"
    end

    test "lists items with and without stock", %{conn: conn, user: user} do
      on_sale = InventoryHelpers.create_item(user, %{name: "Mug"})
      unlisted = InventoryHelpers.create_item(user, %{name: "Jug", stock: nil})

      {:ok, view, _html} = live(conn, ~p"/inventory/items")

      assert has_element?(view, "[data-item='#{on_sale.id}']", "CHF")
      assert has_element?(view, "[data-item='#{unlisted.id}']", "Nicht im Verkauf")
    end

    test "does not render an inline creation form", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/inventory/items")
      refute html =~ "<form"
    end
  end
end

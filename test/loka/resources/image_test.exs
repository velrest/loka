defmodule Loka.Resources.ImageTest do
  use Loka.DataCase, async: true

  alias Loka.Inventory
  alias Loka.Support.UserHelpers

  setup do
    %{owner: owner} = UserHelpers.create_studio_owner()
    other = UserHelpers.create_user()

    stock =
      Inventory.create_stock!(
        %{
          quantity: 5,
          price: Money.new(:CHF, 100),
          item: %{name: "Widget", description: "A widget"}
        },
        actor: owner
      )

    %{owner: owner, other: other, item: stock.item}
  end

  defp create_image(item, actor) do
    Inventory.create_image(
      %{
        path: "/uploads/items/test.jpg",
        filename: "test.jpg",
        position: 0,
        item_id: item.id
      },
      actor: actor
    )
  end

  describe "create_image" do
    test "studio owner can create an image for their item", %{owner: owner, item: item} do
      assert {:ok, image} = create_image(item, owner)
      assert image.path == "/uploads/items/test.jpg"
      assert image.filename == "test.jpg"
      assert image.position == 0
    end

    test "actor without a studio cannot create an image", %{item: item} do
      no_studio_user = UserHelpers.create_user()
      assert {:error, _} = create_image(item, no_studio_user)
    end

    test "unauthenticated actor cannot create an image", %{item: item} do
      assert {:error, _} =
               Inventory.create_image(%{
                 path: "/uploads/items/test.jpg",
                 filename: "test.jpg",
                 position: 0,
                 item_id: item.id
               })
    end
  end

  describe "delete_image" do
    setup %{owner: owner, item: item} do
      {:ok, image} = create_image(item, owner)
      %{image: image}
    end

    test "studio owner can delete their image", %{owner: owner, image: image} do
      assert :ok = Inventory.delete_image(image, actor: owner)
    end

    test "non-owner cannot delete the image", %{other: other, image: image} do
      assert {:error, _} = Inventory.delete_image(image, actor: other)
    end

    test "unauthenticated actor cannot delete an image", %{image: image} do
      assert {:error, _} = Inventory.delete_image(image)
    end
  end

  describe "list_item_images" do
    test "returns images for an item ordered by position", %{owner: owner, item: item} do
      {:ok, _} =
        Inventory.create_image(
          %{path: "/uploads/items/b.jpg", filename: "b.jpg", position: 1, item_id: item.id},
          actor: owner
        )

      {:ok, _} =
        Inventory.create_image(
          %{path: "/uploads/items/a.jpg", filename: "a.jpg", position: 0, item_id: item.id},
          actor: owner
        )

      assert {:ok, images} = Inventory.list_item_images(item.id)
      assert length(images) == 2
      assert hd(images).position == 0
      assert List.last(images).position == 1
    end
  end
end

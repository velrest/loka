defmodule Loka.Resources.ImageTest do
  use Loka.DataCase, async: true

  alias Loka.Inventory
  alias Loka.Support.{InventoryHelpers, UserHelpers}

  setup do
    %{owner: owner} = UserHelpers.create_studio_owner()
    %{owner: other_owner} = UserHelpers.create_studio_owner()
    other = UserHelpers.create_user()

    item = InventoryHelpers.create_item(owner)

    %{owner: owner, other_owner: other_owner, other: other, item: item}
  end

  defp make_upload(filename \\ "test.jpg") do
    tmp_path = Path.join(System.tmp_dir!(), "#{System.unique_integer([:positive])}_#{filename}")
    File.write!(tmp_path, "fake image content")
    %Plug.Upload{path: tmp_path, filename: filename, content_type: "image/jpeg"}
  end

  defp create_image(item, actor) do
    Inventory.create_image(item.id, make_upload(), %{}, actor: actor)
  end

  describe "create_image" do
    test "studio owner can create an image for their item", %{owner: owner, item: item} do
      assert {:ok, image} = create_image(item, owner)
      assert is_binary(image.path)
      assert is_binary(image.filename)
      assert image.position == 0
    end

    test "studio owner can add images to an item that isn't on sale", %{owner: owner} do
      item = InventoryHelpers.create_item(owner, %{stock: nil})
      assert {:ok, _image} = create_image(item, owner)
    end

    test "owner of another studio cannot create an image for the item",
         %{other_owner: other_owner, item: item} do
      assert {:error, %Ash.Error.Forbidden{}} = create_image(item, other_owner)
    end

    test "actor without a studio cannot create an image", %{item: item} do
      no_studio_user = UserHelpers.create_user()
      assert {:error, _} = create_image(item, no_studio_user)
    end

    test "unauthenticated actor cannot create an image", %{item: item} do
      assert {:error, _} = Inventory.create_image(item.id, nil)
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

    test "owner of another studio cannot delete the image",
         %{other_owner: other_owner, image: image} do
      assert {:error, _} = Inventory.delete_image(image, actor: other_owner)
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
      Inventory.create_image!(item.id, make_upload("b.jpg"), %{}, actor: owner)
      Inventory.create_image!(item.id, make_upload("a.jpg"), %{}, actor: owner)

      images = Inventory.list_item_images!(item.id)
      assert length(images) == 2
      assert hd(images).position == 0
      assert List.last(images).position == 1
    end
  end
end

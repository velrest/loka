defmodule Loka.Changes.Image.RemoveFile do
  @moduledoc "Deletes an image's file from disk after the record is destroyed."

  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, record ->
      File.rm(Loka.Uploads.path(record.path))
      {:ok, record}
    end)
  end
end

defmodule Loka.Changes.Image.UploadFile do
  @moduledoc """
  Saves an uploaded image under `items/` in `Loka.Uploads.dir/0` and appends it
  after the item's existing images.
  """

  use Ash.Resource.Change

  def change(changeset, _opts, %{actor: actor}) do
    file = Ash.Changeset.get_argument(changeset, :file)
    item_id = Ash.Changeset.get_argument(changeset, :item_id)

    if is_nil(file) or is_nil(item_id) do
      changeset
    else
      filename = "#{Ecto.UUID.generate()}#{Path.extname(file.source.filename)}"
      web_path = "/uploads/items/#{item_id}/#{filename}"

      changeset
      |> Ash.Changeset.change_attribute(:path, web_path)
      |> Ash.Changeset.change_attribute(:filename, filename)
      |> Ash.Changeset.change_attribute(
        :position,
        Loka.Inventory.Image
        |> Ash.Query.for_read(:list_item_images, %{item_id: item_id})
        |> Ash.count!(actor: actor)
      )
      |> Ash.Changeset.after_action(fn _changeset, record ->
        dest = Loka.Uploads.path(record.path)
        File.mkdir_p!(Path.dirname(dest))
        {:ok, src_path} = Ash.Type.File.path(file)
        File.cp!(src_path, dest)
        {:ok, record}
      end)
    end
  end
end

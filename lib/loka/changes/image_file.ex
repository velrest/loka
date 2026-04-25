defmodule Loka.Changes.Image.RemoveFile do
  use Ash.Resource.Change

  def change(changeset, _opts, _context), do: changeset

  def after_action(_changeset, record, _context) do
    File.rm(Path.join([:code.priv_dir(:loka), "static", String.trim_leading(record.path, "/")]))
    {:ok, record}
  end
end

defmodule Loka.Changes.Image.UploadFile do
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
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
      |> Ash.Changeset.change_attribute(:position, length(Loka.Inventory.list_item_images!(item_id)))
    end
  end

  def after_action(changeset, record, _context) do
    file = Ash.Changeset.get_argument(changeset, :file)

    if is_nil(file) do
      {:ok, record}
    else
      dest = Path.join([:code.priv_dir(:loka), "static", String.trim_leading(record.path, "/")])
      File.mkdir_p!(Path.dirname(dest))
      {:ok, src_path} = Ash.Type.File.path(file)
      File.cp!(src_path, dest)
      {:ok, record}
    end
  end
end

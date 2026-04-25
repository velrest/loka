defmodule Loka.Changes.Image.RemoveFile do
  use Ash.Resource.Change

  def change(changeset, _opts, %{actor: actor}) when not is_nil(actor) do
    File.rm(
      Path.join([:code.priv_dir(:loka), "static", String.trim_leading(changeset.data.path, "/")])
    )

    changeset
  end

  def change(changeset, _opts, _context), do: changeset
end

defmodule Loka.Changes.Image.UploadFile do
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    file = Ash.Changeset.get_argument(changeset, :file)
    item_id = Ash.Changeset.get_argument(changeset, :item_id)

    if is_nil(file) or is_nil(item_id), do: changeset, else: do_upload(changeset, file, item_id)
  end

  defp do_upload(changeset, file, item_id) do
    dest_dir = Path.join([:code.priv_dir(:loka), "static", "uploads", "items", item_id])
    File.mkdir_p!(dest_dir)
    {:ok, src_path} = Ash.Type.File.path(file)
    filename = "#{Ecto.UUID.generate()}#{Path.extname(file.source.filename)}"
    dest = Path.join(dest_dir, filename)
    File.cp!(src_path, dest)

    [_, web_path] = String.split(dest, "/priv/static")

    changeset
    |> Ash.Changeset.change_attribute(:path, web_path)
    |> Ash.Changeset.change_attribute(:filename, filename)
    |> Ash.Changeset.change_attribute(
      :position,
      length(Loka.Inventory.list_item_images!(item_id))
    )
  end
end

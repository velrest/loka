defmodule Loka.Changes.RemoveImageFile do
  use Ash.Resource.Change

  def change(changeset, _opts, %{actor: actor}) when not is_nil(actor) do
    File.rm(
      Path.join([:code.priv_dir(:loka), "static", String.trim_leading(changeset.path, "/")])
    )

    changeset
  end

  def change(changeset, _opts, _context), do: changeset
end

defmodule Loka.Uploads do
  @moduledoc """
  Location of user uploads on disk, served at `/uploads`.

  Defaults to `priv/static/uploads`. Releases set `UPLOADS_DIR` to a directory
  outside the release, since the release's priv dir is replaced on every deploy.
  """

  def dir do
    Application.get_env(:loka, :uploads_dir) ||
      Path.join(:code.priv_dir(:loka), "static/uploads")
  end

  @doc "Maps a web path like `/uploads/items/1/a.jpg` to its file on disk."
  def path("/uploads/" <> rest), do: Path.join(dir(), rest)
end

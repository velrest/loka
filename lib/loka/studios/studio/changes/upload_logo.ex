defmodule Loka.Studios.Studio.Changes.UploadLogo do
  @moduledoc """
  Saves an uploaded logo under `priv/static/uploads/studios/` and deletes the
  previous one.
  """

  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    file = Ash.Changeset.get_argument(changeset, :logo)

    if is_nil(file) do
      changeset
    else
      studio_id = changeset.data.id
      filename = "#{Ecto.UUID.generate()}#{Path.extname(file.source.filename)}"
      web_path = "/uploads/studios/#{studio_id}/#{filename}"
      old_path = changeset.data.logo_path

      changeset
      |> Ash.Changeset.change_attribute(:logo_path, web_path)
      |> Ash.Changeset.after_action(fn _changeset, record ->
        replace_file(file, web_path, old_path)
        {:ok, record}
      end)
    end
  end

  defp replace_file(file, web_path, old_path) do
    dest = static_path(web_path)
    File.mkdir_p!(Path.dirname(dest))
    {:ok, src_path} = Ash.Type.File.path(file)
    File.cp!(src_path, dest)

    if old_path, do: File.rm(static_path(old_path))
  end

  defp static_path(web_path) do
    Path.join([:code.priv_dir(:loka), "static", String.trim_leading(web_path, "/")])
  end
end

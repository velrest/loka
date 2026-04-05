defmodule Loka.Changes.SetStudioFromActor do
  use Ash.Resource.Change

  def change(changeset, _opts, %{actor: actor}) when not is_nil(actor) do
    case Loka.Studios.get_own_studio(actor: actor) do
      {:ok, studio} when not is_nil(studio) ->
        Ash.Changeset.force_change_attribute(changeset, :studio_id, studio.id)

      _ ->
        changeset
    end
  end

  def change(changeset, _opts, _context), do: changeset
end

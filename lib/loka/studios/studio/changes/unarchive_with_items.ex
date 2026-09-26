defmodule Loka.Studios.Studio.Changes.UnarchiveWithItems do
  @moduledoc """
  Un-archives a studio together with the items (and their stock) that were
  archived with it, i.e. at or after the studio's own `archived_at`. Items the
  owner archived on their own before stay archived.
  """

  use Ash.Resource.Change

  alias Loka.Inventory

  @impl true
  def change(changeset, _opts, context) do
    archived_at = changeset.data.archived_at

    changeset
    |> Ash.Changeset.change_attribute(:archived_at, nil)
    |> Ash.Changeset.after_action(fn _changeset, studio ->
      opts = Ash.Context.to_opts(context)

      studio.id
      |> Inventory.list_archived_studio_items!(archived_at, opts)
      |> Enum.each(&Inventory.unarchive_item!(&1, opts))

      {:ok, studio}
    end)
  end
end

defmodule Loka.Inventory.Item.Changes.UnarchiveWithStock do
  @moduledoc """
  Un-archives an item together with the stock that was archived with it (at or
  after the item's own `archived_at`). Stock taken off sale before stays
  archived.
  """

  use Ash.Resource.Change

  alias Loka.Inventory

  @impl true
  def change(changeset, _opts, context) do
    archived_at = changeset.data.archived_at

    changeset
    |> Ash.Changeset.change_attribute(:archived_at, nil)
    |> Ash.Changeset.after_action(fn _changeset, item ->
      opts = Ash.Context.to_opts(context)

      item.id
      |> Inventory.list_archived_item_stock!(archived_at, opts)
      |> Enum.each(&Inventory.unarchive_stock!(&1, opts))

      {:ok, item}
    end)
  end
end

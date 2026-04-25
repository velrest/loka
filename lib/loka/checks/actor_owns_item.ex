defmodule Loka.Checks.ActorOwnsItem do
  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts), do: "actor owns the item through their studio"

  @impl true
  def match?(actor, %{changeset: changeset}, _opts) do
    item_id = Ash.Changeset.get_argument(changeset, :item_id)

    if is_nil(item_id) or is_nil(actor) do
      false
    else
      case Loka.Inventory.get_stock_for_item(item_id, actor: actor) do
        {:ok, stock} when not is_nil(stock) -> true
        _ -> false
      end
    end
  end
end

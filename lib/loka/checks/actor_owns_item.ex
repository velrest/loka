defmodule Loka.Checks.ActorOwnsItem do
  @moduledoc """
  Policy check: the item given by `item_id` (argument or attribute) belongs to
  the actor's studio.
  """

  use Ash.Policy.SimpleCheck

  @impl true
  def describe(_opts), do: "actor owns the item through their studio"

  @impl true
  def match?(nil, _context, _opts), do: false

  def match?(actor, %{changeset: changeset}, _opts) do
    case Ash.Changeset.get_argument_or_attribute(changeset, :item_id) do
      nil ->
        false

      item_id ->
        match?({:ok, %Loka.Inventory.Item{}}, Loka.Inventory.get_own_item(item_id, actor: actor))
    end
  end

  def match?(_actor, _context, _opts), do: false
end

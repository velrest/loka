defmodule Loka.Commerce.Cart.Changes.MergeFrom do
  @moduledoc "Moves all stock from an anonymous cart into this cart, then deletes the anonymous cart."

  use Ash.Resource.Change

  alias Loka.Commerce

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, cart ->
      anon_cart_id = changeset.arguments.anonymous_cart_id

      # Items that went out of stock in the meantime are dropped
      anon_cart_id
      |> Commerce.list_cart_items!()
      |> Enum.each(&Commerce.add_to_cart(cart.id, &1.item_id))

      anon_cart = Commerce.get_anonymous_cart!(anon_cart_id)
      Commerce.destroy_cart!(anon_cart)

      {:ok, cart}
    end)
  end
end

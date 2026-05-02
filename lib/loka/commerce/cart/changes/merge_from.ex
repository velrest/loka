defmodule Loka.Commerce.Cart.Changes.MergeFrom do
  use Ash.Resource.Change

  alias Loka.Commerce

  @impl true
  def change(changeset, _opts, _context) do
    Ash.Changeset.after_action(changeset, fn _changeset, cart ->
      anon_cart_id = changeset.arguments.anonymous_cart_id

      anon_stocks = Commerce.list_cart_stocks!(anon_cart_id)

      Enum.each(anon_stocks, fn cs ->
        Commerce.add_to_cart!(cart.id, cs.stock_id)
      end)

      anon_cart = Commerce.get_anonymous_cart!(anon_cart_id)
      Commerce.destroy_cart!(anon_cart)

      {:ok, cart}
    end)
  end
end

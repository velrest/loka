defmodule Loka.Commerce.Cart.Changes.MergeFrom do
  use Ash.Resource.Change

  alias Loka.Commerce.{Cart, CartStock}

  @impl true
  def change(changeset, _opts, _context) do
    # TODO this is probably not working
    Ash.Changeset.after_action(changeset, fn _changeset, cart ->
      anon_cart_id = changeset.arguments.anonymous_cart_id

      anon_stocks =
        CartStock
        |> Ash.Query.filter(cart_id == ^anon_cart_id)
        |> Ash.read!(authorize?: false)

      Enum.each(anon_stocks, fn cs ->
        CartStock
        |> Ash.Changeset.for_create(:create, %{cart_id: cart.id, stock_id: cs.stock_id},
          authorize?: false
        )
        |> Ash.create!()
      end)

      Cart
      |> Ash.get!(anon_cart_id, authorize?: false)
      |> Ash.destroy!(authorize?: false)

      {:ok, cart}
    end)
  end
end

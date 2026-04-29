defmodule Loka.Commerce.Cart.Actions.CleanupAnonymous do
  require Ash.Query

  def run(_input, _opts, _context) do
    cutoff = DateTime.add(DateTime.utc_now(), -30, :day)

    Loka.Commerce.Cart
    |> Ash.Query.filter(is_nil(user_id) and updated_at < ^cutoff)
    |> Ash.bulk_destroy!(:destroy, %{}, authorize?: false)

    :ok
  end
end

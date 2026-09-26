defmodule Loka.Commerce.Cart.Actions.CleanupAnonymous do
  @moduledoc "Deletes anonymous carts older than 30 days. Run daily by Oban."

  alias Loka.Commerce

  def run(_input, _opts, _context) do
    cutoff = DateTime.add(DateTime.utc_now(), -30, :day)

    Commerce.list_old_anonymous_carts!(cutoff)
    |> Enum.each(&Commerce.destroy_cart!(&1))

    :ok
  end
end

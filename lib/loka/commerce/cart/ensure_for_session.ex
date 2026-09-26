defmodule Loka.Commerce.Cart.EnsureForSession do
  @moduledoc """
  Returns the cart to use for the current session, creating one if needed.

  Given the actor (if signed in) and an anonymous cart id from the browser:

    * neither cart exists → create a new one
    * only the anonymous cart → assign it to the user if signed in
    * only the user cart → use it
    * both → merge the anonymous cart into the user cart
  """

  alias Loka.Commerce

  def run(input, _opts, context) do
    actor = context.actor
    anonymous_cart_id = input.arguments[:anonymous_cart_id]

    anon_cart =
      with id when not is_nil(id) <- anonymous_cart_id,
           {:ok, cart} when not is_nil(cart) <- Commerce.get_anonymous_cart(id) do
        cart
      else
        _ -> nil
      end

    user_cart = if actor, do: Commerce.get_user_cart!(actor: actor), else: nil

    case {user_cart, anon_cart} do
      {nil, nil} ->
        Commerce.create_cart(actor: actor)

      {nil, anon} when not is_nil(actor) ->
        {:ok, Commerce.assign_to_user!(anon, actor: actor)}

      {nil, anon} ->
        {:ok, anon}

      {cart, nil} ->
        {:ok, cart}

      {cart, anon} ->
        {:ok, Commerce.merge_from!(cart, anon.id, actor: actor)}
    end
  end
end

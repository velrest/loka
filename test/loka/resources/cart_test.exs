defmodule Loka.Resources.CartTest do
  use Loka.DataCase, async: true

  alias Loka.Commerce
  alias Loka.Support.UserHelpers

  setup do
    %{buyer: UserHelpers.create_user()}
  end

  describe "create_anonymous_cart" do
    test "creates a cart with no user" do
      assert {:ok, cart} = Commerce.create_anonymous_cart()
      assert is_nil(cart.user_id)
    end

    test "each call produces a distinct cart" do
      {:ok, cart1} = Commerce.create_anonymous_cart()
      {:ok, cart2} = Commerce.create_anonymous_cart()
      assert cart1.id != cart2.id
    end
  end

  describe "get_anonymous_cart" do
    test "returns cart by id when user_id is nil" do
      {:ok, cart} = Commerce.create_anonymous_cart()
      assert {:ok, found} = Commerce.get_anonymous_cart(cart.id)
      assert found.id == cart.id
    end

    test "returns nil for an unknown id" do
      assert {:ok, nil} = Commerce.get_anonymous_cart(Ash.UUID.generate())
    end

    test "does not return user-owned carts", %{buyer: buyer} do
      {:ok, cart} = Commerce.create_cart(actor: buyer)
      assert {:ok, nil} = Commerce.get_anonymous_cart(cart.id)
    end
  end

  describe "assign_to_user" do
    test "sets user_id on an anonymous cart", %{buyer: buyer} do
      {:ok, anon_cart} = Commerce.create_anonymous_cart()

      {:ok, cart} =
        anon_cart
        |> Ash.Changeset.for_update(:assign_to_user, %{}, actor: buyer)
        |> Ash.update()

      assert cart.user_id == buyer.id
    end

    test "requires an actor" do
      {:ok, anon_cart} = Commerce.create_anonymous_cart()

      assert {:error, _} =
               anon_cart
               |> Ash.Changeset.for_update(:assign_to_user, %{})
               |> Ash.update()
    end
  end

  describe "destroy" do
    test "allows destroying a cart", %{buyer: buyer} do
      {:ok, cart} = Commerce.create_anonymous_cart()
      assert :ok = Ash.destroy(cart, actor: buyer)
    end
  end

  describe "merge_from" do
    setup do
      %{owner: owner} = UserHelpers.create_studio_owner()

      stock =
        Loka.Inventory.create_stock!(
          %{name: "Widget", description: "A widget"},
          %{quantity: 10, price: Money.new(:CHF, 500)},
          actor: owner
        )

      %{stock: stock}
    end

    test "copies items from anonymous cart into user cart", %{buyer: buyer, stock: stock} do
      {:ok, anon_cart} = Commerce.create_anonymous_cart()
      Commerce.add_to_cart!(anon_cart.id, stock.id)

      {:ok, user_cart} = Commerce.create_cart(actor: buyer)

      {:ok, merged} =
        user_cart
        |> Ash.Changeset.for_update(:merge_from, %{anonymous_cart_id: anon_cart.id}, actor: buyer)
        |> Ash.update()

      merged = Ash.load!(merged, :cart_stocks, actor: buyer)
      assert length(merged.cart_stocks) == 1
    end

    test "deletes the anonymous cart after merge", %{buyer: buyer, stock: stock} do
      {:ok, anon_cart} = Commerce.create_anonymous_cart()
      Commerce.add_to_cart!(anon_cart.id, stock.id)
      anon_cart_id = anon_cart.id

      {:ok, user_cart} = Commerce.create_cart(actor: buyer)

      user_cart
      |> Ash.Changeset.for_update(:merge_from, %{anonymous_cart_id: anon_cart_id}, actor: buyer)
      |> Ash.update!()

      assert {:ok, nil} = Commerce.get_anonymous_cart(anon_cart_id)
    end

    test "requires an actor" do
      {:ok, anon_cart} = Commerce.create_anonymous_cart()
      {:ok, user_cart} = Commerce.create_anonymous_cart()

      assert {:error, _} =
               user_cart
               |> Ash.Changeset.for_update(:merge_from, %{anonymous_cart_id: anon_cart.id})
               |> Ash.update()
    end
  end

  describe "ensure_cart_for_session" do
    setup do
      %{owner: owner} = UserHelpers.create_studio_owner()

      stock =
        Loka.Inventory.create_stock!(
          %{name: "Widget", description: "A widget"},
          %{quantity: 10, price: Money.new(:CHF, 500)},
          actor: owner
        )

      %{stock: stock}
    end

    test "anonymous user + no cart ID → creates anonymous cart" do
      assert {:ok, cart} = Commerce.ensure_cart_for_session(%{})
      assert is_nil(cart.user_id)
    end

    test "anonymous user + valid cart ID → returns existing cart" do
      {:ok, anon_cart} = Commerce.create_anonymous_cart()
      assert {:ok, cart} = Commerce.ensure_cart_for_session(%{anonymous_cart_id: anon_cart.id})
      assert cart.id == anon_cart.id
    end

    test "anonymous user + unknown cart ID → creates new anonymous cart" do
      assert {:ok, cart} =
               Commerce.ensure_cart_for_session(%{anonymous_cart_id: Ash.UUID.generate()})

      assert is_nil(cart.user_id)
    end

    test "logged-in user + no cart + no anon cart → creates user cart", %{buyer: buyer} do
      assert {:ok, cart} = Commerce.ensure_cart_for_session(%{}, actor: buyer)
      assert cart.user_id == buyer.id
    end

    test "logged-in user + no user cart + anon cart → assigns anon cart to user",
         %{buyer: buyer} do
      {:ok, anon_cart} = Commerce.create_anonymous_cart()

      assert {:ok, cart} =
               Commerce.ensure_cart_for_session(%{anonymous_cart_id: anon_cart.id}, actor: buyer)

      assert cart.id == anon_cart.id
      assert cart.user_id == buyer.id
    end

    test "logged-in user + existing user cart + no anon cart → returns user cart",
         %{buyer: buyer} do
      {:ok, user_cart} = Commerce.create_cart(actor: buyer)
      assert {:ok, cart} = Commerce.ensure_cart_for_session(%{}, actor: buyer)
      assert cart.id == user_cart.id
    end

    test "logged-in user + user cart + anon cart → merges and returns user cart",
         %{buyer: buyer, stock: stock} do
      {:ok, anon_cart} = Commerce.create_anonymous_cart()
      Commerce.add_to_cart!(anon_cart.id, stock.id)
      anon_cart_id = anon_cart.id

      {:ok, user_cart} = Commerce.create_cart(actor: buyer)

      assert {:ok, cart} =
               Commerce.ensure_cart_for_session(%{anonymous_cart_id: anon_cart.id}, actor: buyer)

      assert cart.id == user_cart.id
      cart = Ash.load!(cart, :cart_stocks, actor: buyer)
      assert length(cart.cart_stocks) == 1
      assert {:ok, nil} = Commerce.get_anonymous_cart(anon_cart_id)
    end
  end

  describe "cleanup_anonymous" do
    test "deletes anonymous carts not modified in 30+ days" do
      {:ok, old_cart} = Commerce.create_anonymous_cart()

      Loka.Repo.query!(
        "UPDATE cart SET updated_at = $1 WHERE id = $2",
        [DateTime.add(DateTime.utc_now(), -31, :day), Ecto.UUID.dump!(old_cart.id)]
      )

      {:ok, fresh_cart} = Commerce.create_anonymous_cart()

      assert :ok = Commerce.cleanup_anonymous(authorize?: false)

      assert {:ok, nil} = Commerce.get_anonymous_cart(old_cart.id)
      assert {:ok, _} = Commerce.get_anonymous_cart(fresh_cart.id)
    end

    test "does not delete user-owned carts older than 30 days", %{buyer: buyer} do
      {:ok, user_cart} = Commerce.create_cart(actor: buyer)

      Loka.Repo.query!(
        "UPDATE cart SET updated_at = $1 WHERE id = $2",
        [DateTime.add(DateTime.utc_now(), -31, :day), Ecto.UUID.dump!(user_cart.id)]
      )

      assert :ok = Commerce.cleanup_anonymous(authorize?: false)

      assert {:ok, cart} = Commerce.get_user_cart(actor: buyer)
      assert cart.id == user_cart.id
    end
  end
end

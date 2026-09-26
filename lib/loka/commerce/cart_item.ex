defmodule Loka.Commerce.CartItem do
  @moduledoc """
  One piece of an item in a cart. Adding the same item twice adds two rows.

  Carts hold items rather than stock, so they always use the item's current
  price; an item whose stock is archived stays in the cart as unavailable.
  """

  use Ash.Resource,
    otp_app: :loka,
    domain: Loka.Commerce,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "cart_items"
    repo Loka.Repo

    references do
      reference :cart, on_delete: :delete
    end
  end

  actions do
    defaults [:read]

    read :for_cart do
      argument :cart_id, :uuid, allow_nil?: false
      filter expr(cart_id == ^arg(:cart_id))
    end

    create :create do
      primary? true
      accept [:cart_id, :item_id]
      validate Loka.Commerce.CartItem.Validations.ItemInStock
    end

    destroy :destroy do
      primary? true
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if relates_to_actor_via([:cart, :user])
      authorize_if expr(is_nil(cart.user_id))
    end

    policy action_type(:create) do
      authorize_if always()
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via([:cart, :user])
      authorize_if expr(is_nil(cart.user_id))
    end
  end

  attributes do
    uuid_v7_primary_key :id

    timestamps()
  end

  relationships do
    belongs_to :item, Loka.Inventory.Item do
      allow_nil? false
      public? true
    end

    belongs_to :cart, Loka.Commerce.Cart do
      allow_nil? false
    end
  end
end

defmodule Loka.Commerce.CartItem.Validations.ItemInStock do
  @moduledoc "Only items with current stock left can be added to a cart."

  use Ash.Resource.Validation

  @impl true
  def validate(changeset, _opts, context) do
    item_id = Ash.Changeset.get_attribute(changeset, :item_id)

    case item_id && Loka.Inventory.get_item(item_id, actor: context.actor) do
      {:ok, %{in_stock?: true}} -> :ok
      _ -> {:error, field: :item_id, message: "is not in stock"}
    end
  end
end

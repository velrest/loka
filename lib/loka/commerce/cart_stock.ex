defmodule Loka.Commerce.CartStock do
  use Ash.Resource,
    otp_app: :loka,
    domain: Loka.Commerce,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "cart_stock"
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
      accept [:cart_id, :stock_id]
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
    belongs_to :stock, Loka.Inventory.Stock do
      allow_nil? false
      public? true
    end

    belongs_to :cart, Loka.Commerce.Cart do
      allow_nil? false
    end
  end
end

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

    create :create do
      primary? true
      accept [:cart_id, :stock_id]
    end
  end

  policies do
    policy action_type(:read) do
      # TODO: this won't work for anonymous cart
      authorize_if relates_to_actor_via([:cart, :user])
    end

    policy action_type(:create) do
      authorize_if always()
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

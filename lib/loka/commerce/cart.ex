defmodule Loka.Commerce.CartStock do
  use Ash.Resource,
    otp_app: :loka,
    domain: Loka.Commerce,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "cart_stock"
    repo Loka.Repo
  end

  attributes do
    uuid_v7_primary_key :id

    timestamps()
  end

  relationships do
    belongs_to :stock, Loka.Inventory.Stock
    belongs_to :cart, Loka.Commerce.Cart
  end
end

defmodule Loka.Commerce.Cart do
  use Ash.Resource,
    otp_app: :loka,
    domain: Loka.Commerce,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "cart"
    repo Loka.Repo
  end

  actions do
    defaults [:read]

    read :read_cart
  end

  policies do
    policy action_type(:read) do
      authorize_if relates_to_actor_via(:user)
    end
  end

  attributes do
    uuid_v7_primary_key :id

    timestamps()
  end

  relationships do
    has_many :cart_stocks, Loka.Commerce.CartStock

    many_to_many :stocks, Loka.Inventory.Stock do
      through Loka.Commerce.CartStock
      join_relationship :cart_stocks
    end

    belongs_to :user, Loka.Accounts.User
  end
end

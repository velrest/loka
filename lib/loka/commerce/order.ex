defmodule Loka.Commerce.OrderLine do
  use Ash.Resource,
    otp_app: :loka,
    domain: Loka.Commerce,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "order_lines"
    repo Loka.Repo
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      accept [:unit_price, :quantity, :stock_id]
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if relates_to_actor_via([:order, :user])
    end

    policy action_type(:create) do
      authorize_if always()
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :unit_price, :money do
      allow_nil? false
      public? true
    end

    attribute :quantity, :integer do
      allow_nil? false
      public? true
      constraints min: 1
    end

    timestamps()
  end

  relationships do
    belongs_to :order, Loka.Commerce.Order do
      allow_nil? false
    end

    belongs_to :stock, Loka.Inventory.Stock do
      allow_nil? false
      public? true
    end
  end
end

defmodule Loka.Commerce.Order do
  use Ash.Resource,
    otp_app: :loka,
    domain: Loka.Commerce,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "orders"
    repo Loka.Repo
  end

  actions do
    defaults [:read]

    read :list_user_orders do
      filter expr(user_id == ^actor(:id))
      prepare build(sort: [inserted_at: :desc])
    end

    read :get_order do
      get_by :id
    end

    create :place_order do
      argument :lines, {:array, :map}, allow_nil?: false

      change set_attribute(:status, :pending)
      change relate_actor(:user)

      change manage_relationship(:lines, :order_lines,
               type: :create,
               on_no_match: :create,
               on_match: :ignore
             )
    end

    update :mark_paid do
      accept []
      change set_attribute(:status, :paid)
    end

    update :fulfil do
      accept []
      change set_attribute(:status, :fulfilled)
    end

    update :cancel do
      accept []
      change set_attribute(:status, :cancelled)
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if relates_to_actor_via(:user)
    end

    policy action(:place_order) do
      authorize_if actor_present()
    end

    policy action(:mark_paid) do
      authorize_if relates_to_actor_via([:order_lines, :stock, :studio, :owner])
    end

    policy action(:fulfil) do
      authorize_if relates_to_actor_via([:order_lines, :stock, :studio, :owner])
    end

    policy action(:cancel) do
      authorize_if relates_to_actor_via(:user)
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :status, :atom do
      allow_nil? false
      public? true
      constraints one_of: [:pending, :paid, :fulfilled, :cancelled]
      default :pending
    end

    timestamps()
  end

  relationships do
    belongs_to :user, Loka.Accounts.User do
      allow_nil? false
      public? true
    end

    has_many :order_lines, Loka.Commerce.OrderLine do
      public? true
    end
  end
end

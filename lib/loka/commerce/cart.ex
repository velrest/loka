defmodule Loka.Commerce.Cart do
  use Ash.Resource,
    otp_app: :loka,
    domain: Loka.Commerce,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer],
    extensions: [AshOban]

  postgres do
    table "cart"
    repo Loka.Repo
  end

  oban do
    triggers do
      trigger :cleanup_anonymous_carts do
        scheduler_cron "@daily"
        action :cleanup_anonymous
        worker_module_name Loka.Commerce.Cart.AshOban.Worker.CleanupAnonymousCarts
        scheduler_module_name Loka.Commerce.Cart.AshOban.Scheduler.CleanupAnonymousCarts
      end
    end
  end

  actions do
    defaults [:read]

    create :create do
      primary? true
      change relate_actor(:user)
    end

    create :create_anonymous do
      accept []
    end

    read :for_user do
      get? true
      filter expr(user_id == ^actor(:id))
    end

    read :for_anonymous do
      get? true
      argument :id, :uuid, allow_nil?: false
      filter expr(id == ^arg(:id) and is_nil(user_id))
    end

    update :assign_to_user do
      accept []
      require_atomic? false
      change relate_actor(:user)
    end

    destroy :destroy do
      primary? true
    end

    update :merge_from do
      require_atomic? false
      argument :anonymous_cart_id, :uuid, allow_nil?: false
      change Loka.Commerce.Cart.Changes.MergeFrom
    end

    action :ensure_for_session, :struct do
      constraints instance_of: __MODULE__
      argument :anonymous_cart_id, :uuid, allow_nil?: true
      run Loka.Commerce.Cart.EnsureForSession
    end

    action :cleanup_anonymous do
      run Loka.Commerce.Cart.Actions.CleanupAnonymous
    end
  end

  policies do
    bypass action(:cleanup_anonymous) do
      authorize_if always()
    end

    bypass action(:ensure_for_session) do
      authorize_if always()
    end

    bypass action(:for_anonymous) do
      authorize_if always()
    end

    bypass action(:create_anonymous) do
      authorize_if always()
    end

    policy action_type(:read) do
      authorize_if relates_to_actor_via(:user)
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action(:assign_to_user) do
      authorize_if actor_present()
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via(:user)
      authorize_if expr(is_nil(:user))
    end

    policy action(:merge_from) do
      authorize_if actor_present()
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

    belongs_to :user, Loka.Accounts.User do
      allow_nil? true
    end
  end

  calculations do
    calculate :subtotal, AshMoney.Types.Money, {Loka.Commerce.Cart.SubtotalCalc, []}
  end

  aggregates do
    count :item_count, :cart_stocks
  end
end

defmodule Loka.Commerce.Cart.SubtotalCalc do
  use Ash.Resource.Calculation

  @impl true
  def load(_, _, _), do: [:stocks]

  @impl true
  def calculate(records, _, _) do
    Enum.map(records, fn cart ->
      prices = Enum.map(cart.stocks, & &1.price)
      if prices == [], do: nil, else: Money.sum!(prices)
    end)
  end
end

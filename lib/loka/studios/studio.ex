defmodule Loka.Studios.Studio do
  use Ash.Resource,
    otp_app: :loka,
    domain: Loka.Studios,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource, AshArchival.Resource],
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "studios"
    repo Loka.Repo
  end

  paper_trail do
    primary_key_type(:uuid_v7)
    change_tracking_mode(:changes_only)
    store_action_name?(true)
    ignore_attributes([:inserted_at, :updated_at])
    # This is handled by ash_archival
    ignore_actions([:destroy])
  end

  actions do
    defaults [:read]

    read :list_all_studios

    read :get_own_studio do
      get? true
      filter expr(owner == ^actor(:id))
    end

    create :create_studio do
      accept [:name]

      change relate_actor(:owner)
    end

    update :update_studio do
      accept [:name]
    end

    destroy :archive_studio
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if actor_present()
      authorize_if expr(not actor(:studio))
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via(:owner)
    end

    policy action_type(:update) do
      authorize_if relates_to_actor_via(:owner)
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :owner, Loka.Accounts.User
    has_many :stock, Loka.Inventory.Stock
  end
end

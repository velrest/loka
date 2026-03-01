defmodule Loka.Inventory.Item do
  use Ash.Resource,
    otp_app: :loka,
    domain: Loka.Inventory,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource, AshArchival.Resource],
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "items"
    repo Loka.Repo
  end

  actions do
    defaults [:read]

    read :list_all_items

    create :create_item do
      accept [:name, :description, :price]
    end

    destroy :archive_item
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if actor_present()
    end

    policy action_type(:destroy) do
      authorize_if actor_present()
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    attribute :description, :string do
      allow_nil? false
      public? true
    end

    attribute :price, :money do
      allow_nil? false
      public? true
      constraints min: Decimal.new("0")
    end

    timestamps()

    paper_trail do
      primary_key_type(:uuid_v7)
      change_tracking_mode(:changes_only)
      store_action_name?(true)
      ignore_attributes([:inserted_at, :updated_at])
      # This is handled by ash_archival
      ignore_actions([:destroy])
    end
  end
end

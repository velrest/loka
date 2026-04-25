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

  paper_trail do
    primary_key_type(:uuid_v7)
    change_tracking_mode(:changes_only)
    store_action_name?(true)
    ignore_attributes([:inserted_at, :updated_at])
    ignore_actions([:destroy])
  end

  actions do
    defaults [:read]

    read :list_all_items

    read :get_item do
      get_by :id
      prepare build(load: [:images, :stock])
    end

    create :create_item do
      primary? true
      accept [:name, :description]
    end

    update :update_item do
      accept [:name, :description]
    end

    destroy :archive_item
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if actor_attribute_equals(:has_studio?, true)
    end

    policy action_type(:update) do
      authorize_if relates_to_actor_via([:stock, :studio, :owner])
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via([:stock, :studio, :owner])
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

    timestamps()
  end

  relationships do
    has_many :stock, Loka.Inventory.Stock
    has_many :images, Loka.Inventory.Image
  end
end

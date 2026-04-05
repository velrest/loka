defmodule Loka.Inventory.Image do
  use Ash.Resource,
    otp_app: :loka,
    domain: Loka.Inventory,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "images"
    repo Loka.Repo
  end

  actions do
    defaults [:read]

    read :list_item_images do
      argument :item_id, :uuid, allow_nil?: false
      filter expr(item_id == ^arg(:item_id))
      prepare build(sort: [position: :asc])
    end

    create :create_image do
      accept [:path, :filename, :position, :item_id]
    end

    destroy :delete_image
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if Loka.Checks.ActorHasStudio
    end

    policy action_type(:destroy) do
      authorize_if expr(exists(item.stock, studio.owner_id == ^actor(:id)))
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :path, :string do
      allow_nil? false
      public? true
    end

    attribute :filename, :string do
      allow_nil? false
      public? true
    end

    attribute :position, :integer do
      allow_nil? false
      public? true
      default 0
    end

    timestamps()
  end

  relationships do
    belongs_to :item, Loka.Inventory.Item do
      allow_nil? false
      public? true
    end
  end
end

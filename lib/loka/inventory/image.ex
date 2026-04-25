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

    read :get_image do
      get_by :id
    end

    read :list_item_images do
      argument :item_id, :uuid, allow_nil?: false
      filter expr(item_id == ^arg(:item_id))
      prepare build(sort: [position: :asc])
    end

    create :create_image do
      argument :item_id, :uuid, allow_nil?: false
      argument :file, :file, allow_nil?: false
      change manage_relationship(:item_id, :item, type: :append)
      change Loka.Changes.Image.UploadFile
    end

    destroy :delete_image do
      require_atomic? false
      change Loka.Changes.Image.RemoveFile
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if Loka.Checks.ActorOwnsItem
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via([:item, :stock, :studio, :owner])
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

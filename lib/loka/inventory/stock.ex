defmodule Loka.Inventory.Stock do
  use Ash.Resource,
    otp_app: :loka,
    domain: Loka.Inventory,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource, AshArchival.Resource],
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "stock"
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

    read :list_all_stock do
      prepare build(load: [item: [:images]])
    end

    read :list_studio_stock do
      prepare build(load: [:item])
    end

    read :get_stock do
      get_by :id
      prepare build(load: [:item])
    end

    read :get_stock_for_item do
      argument :item_id, :uuid, allow_nil?: false
      get? true
      filter expr(item_id == ^arg(:item_id) and studio.owner_id == ^actor(:id))
    end

    create :create_stock do
      accept [:quantity, :price]
      argument :item, :map, allow_nil?: false

      change manage_relationship(:item, type: :create)

      change fn changeset, %{actor: actor} ->
        with actor when not is_nil(actor) <- actor,
             {:ok, %{studio: %{id: studio_id}}} <- Ash.load(actor, :studio) do
          Ash.Changeset.force_change_attribute(changeset, :studio_id, studio_id)
        else
          _ -> changeset
        end
      end
    end

    update :update_stock do
      accept [:quantity, :price]
    end

    destroy :archive_stock
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if actor_attribute_equals(:has_studio?, true)
    end

    policy action_type(:update) do
      authorize_if relates_to_actor_via([:studio, :owner])
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via([:studio, :owner])
    end
  end

  attributes do
    uuid_v7_primary_key :id

    attribute :quantity, :integer do
      allow_nil? false
      public? true
      constraints min: 0
    end

    attribute :price, :money do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :item, Loka.Inventory.Item do
      allow_nil? false
    end

    belongs_to :studio, Loka.Studios.Studio do
      allow_nil? false
    end

    many_to_many :carts, Loka.Commerce.Cart do
      through Loka.Commerce.CartStock
    end
  end

  identities do
    identity :unique_item_per_studio, [:item_id, :studio_id]
  end
end

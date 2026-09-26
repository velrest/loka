defmodule Loka.Inventory.Stock do
  @moduledoc """
  The price and quantity an item is on sale for.

  An item has at most one current stock. Price and quantity are edited in
  place (the paper trail keeps the history); to take an item off sale the
  stock is archived, and re-listing it creates a new stock.
  """

  use Ash.Resource,
    otp_app: :loka,
    domain: Loka.Inventory,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshPaperTrail.Resource, AshArchival.Resource],
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "stock"
    repo Loka.Repo

    identity_wheres_to_sql one_current_stock_per_item: "archived_at IS NULL"
  end

  paper_trail do
    primary_key_type(:uuid_v7)
    change_tracking_mode(:changes_only)
    store_action_name?(true)
    ignore_attributes([:inserted_at, :updated_at])
    ignore_actions([:destroy])
  end

  archive do
    exclude_read_actions([:archived_for_item])
  end

  actions do
    defaults [:read]

    create :create_stock do
      primary? true
      accept [:quantity, :price, :item_id]
    end

    update :update_stock do
      accept [:quantity, :price]
    end

    destroy :archive_stock do
      primary? true
    end

    # Stock archived together with its item (at or after `archived_since`),
    # for restoring it with the item
    read :archived_for_item do
      argument :item_id, :uuid, allow_nil?: false
      argument :archived_since, :utc_datetime_usec, allow_nil?: false
      filter expr(item_id == ^arg(:item_id) and archived_at >= ^arg(:archived_since))
    end

    update :unarchive_stock do
      require_atomic? false
      change set_attribute(:archived_at, nil)
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      authorize_if Loka.Checks.ActorOwnsItem
    end

    policy action_type(:update) do
      authorize_if relates_to_actor_via([:item, :studio, :owner])
    end

    policy action_type(:destroy) do
      authorize_if relates_to_actor_via([:item, :studio, :owner])
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
  end

  identities do
    identity :one_current_stock_per_item, [:item_id] do
      where expr(is_nil(archived_at))
      message "item already has stock"
    end
  end
end

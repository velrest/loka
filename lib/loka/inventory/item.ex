defmodule Loka.Inventory.Item do
  @moduledoc """
  A product a studio makes: name, description and images. Archived instead of
  deleted.

  An item has at most one current stock (price and quantity). Items without
  stock, or with none left, are shown but can't be added to a cart. Archiving
  an item archives its stock too.
  """

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

  archive do
    exclude_read_actions([:archived_for_studio, :list_own_archived_items])
    archive_related([:stock])
    # Archiving the item is already authorized, and the stock's own policy
    # can't see the item once it's archived
    archive_related_authorize?(false)
  end

  actions do
    defaults [:read]

    read :list_all_items do
      prepare build(load: [:images, :stock, :studio, :in_stock?])
    end

    read :list_studio_items do
      argument :studio_id, :uuid, allow_nil?: false
      filter expr(studio_id == ^arg(:studio_id))
      prepare build(load: [:images, :stock, :studio, :in_stock?])
    end

    read :get_item do
      get_by :id
      prepare build(load: [:images, :stock, :studio, :in_stock?])
    end

    # An item from the actor's own studio; nil for anyone else's
    read :get_own_item do
      get_by :id
      filter expr(studio.owner_id == ^actor(:id))
    end

    create :create_item do
      primary? true
      accept [:name, :description]
      argument :stock, :map, allow_nil?: true

      change manage_relationship(:stock, type: :create)

      # Items always belong to the actor's own studio
      change fn changeset, %{actor: actor} ->
        with actor when not is_nil(actor) <- actor,
             {:ok, %{studio: %{id: studio_id}}} <- Ash.load(actor, :studio) do
          Ash.Changeset.force_change_attribute(changeset, :studio_id, studio_id)
        else
          _ -> changeset
        end
      end
    end

    update :update_item do
      accept [:name, :description]
    end

    destroy :archive_item do
      primary? true
    end

    # The actor's own archived items, so they can be restored
    read :list_own_archived_items do
      filter expr(studio.owner_id == ^actor(:id) and not is_nil(archived_at))
      prepare build(load: [:images], sort: [archived_at: :desc])
    end

    # Items archived together with their studio (at or after `archived_since`),
    # for restoring them with the studio
    read :archived_for_studio do
      argument :studio_id, :uuid, allow_nil?: false
      argument :archived_since, :utc_datetime_usec, allow_nil?: false
      filter expr(studio_id == ^arg(:studio_id) and archived_at >= ^arg(:archived_since))
    end

    # Restores the item and the stock that was archived with it
    update :unarchive_item do
      require_atomic? false
      change Loka.Inventory.Item.Changes.UnarchiveWithStock
    end
  end

  policies do
    policy action_type(:read) do
      authorize_if always()
    end

    # The studio is always set from the actor, so having one is enough
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
    belongs_to :studio, Loka.Studios.Studio do
      allow_nil? false
    end

    # The current stock; past stocks are archived and filtered out
    has_one :stock, Loka.Inventory.Stock

    has_many :images, Loka.Inventory.Image do
      sort position: :asc
    end
  end

  calculations do
    calculate :in_stock?, :boolean, expr(exists(stock, quantity > 0))
  end
end

defmodule Loka.Studios.Studio do
  @moduledoc """
  A pottery studio. Archived instead of deleted; archiving a studio archives
  its items (and their stock) too, so nothing of it stays visible.

  Latitude and longitude are derived from the postal code (see
  `Loka.Studios.Studio.Changes.GeocodeAddress`).
  """

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

  archive do
    exclude_read_actions([:get_own_archived_studio])
    archive_related([:items])
    # Archiving the studio is already authorized, and the items' own policy
    # can't see the studio once it's archived
    archive_related_authorize?(false)
  end

  actions do
    defaults [:read]

    read :list_all_studios

    read :get_studio do
      get_by :id
    end

    read :get_own_studio do
      get? true
    end

    create :create_studio do
      accept [:name, :street, :house_number, :city, :postal_code]
      change relate_actor(:owner)
      change Loka.Studios.Studio.Changes.GeocodeAddress
    end

    update :update_studio do
      accept [:name, :street, :house_number, :city, :postal_code, :description]
      argument :logo, :file
      require_atomic? false
      change Loka.Studios.Studio.Changes.GeocodeAddress
      change Loka.Studios.Studio.Changes.UploadLogo
    end

    destroy :archive_studio do
      primary? true
    end

    read :get_own_archived_studio do
      get? true
      filter expr(owner_id == ^actor(:id) and not is_nil(archived_at))
    end

    # Restores the studio and the items (with their stock) that were archived
    # with it; items archived on their own before stay archived
    update :unarchive_studio do
      require_atomic? false
      change Loka.Studios.Studio.Changes.UnarchiveWithItems
    end
  end

  policies do
    policy action([:get_own_studio, :get_own_archived_studio]) do
      authorize_if relates_to_actor_via(:owner)
    end

    policy action_type(:read) do
      authorize_if always()
    end

    policy action_type(:create) do
      forbid_if actor_attribute_equals(:has_studio?, true)
      authorize_if actor_present()
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

    attribute :street, :string

    attribute :house_number, :string

    attribute :city, :string do
      allow_nil? false
    end

    attribute :postal_code, :string do
      allow_nil? false
      constraints min_length: 4, max_length: 4, match: ~r/^\d{4}$/
    end

    attribute :description, :string
    attribute :logo_path, :string
    attribute :latitude, :float
    attribute :longitude, :float

    timestamps()
  end

  relationships do
    belongs_to :owner, Loka.Accounts.User
    has_many :items, Loka.Inventory.Item
  end

  identities do
    identity :unique_owner, [:owner_id]
  end
end

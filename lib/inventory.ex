defmodule Loka.Inventory do
  use Ash.Domain,
    otp_app: :loka,
    extensions: [AshPaperTrail.Domain, AshPhoenix, AshAdmin.Domain]

  paper_trail do
    include_versions?(false)
  end

  admin do
    show? true
  end

  resources do
    resource Loka.Inventory.Item do
      define :list_all_items
      define :create_item
      define :archive_item
    end
  end
end

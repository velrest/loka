defmodule Loka.Inventory do
  use Ash.Domain,
    otp_app: :loka,
    extensions: [AshPaperTrail.Domain, AshPhoenix, AshAdmin.Domain]

  paper_trail do
    include_versions?(true)
  end

  admin do
    show? true
  end

  resources do
    resource Loka.Inventory.Item do
      define :list_all_items
      define :update_item
      define :archive_item
    end

    resource Loka.Inventory.Stock do
      define :list_all_stock
      define :create_stock
      define :update_stock
      define :archive_stock
    end
  end
end

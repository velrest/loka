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
      define :get_item, args: [:id], not_found_error?: false
      define :update_item
      define :archive_item
    end

    resource Loka.Inventory.Stock do
      define :list_all_stock
      define :list_studio_stock
      define :get_stock, args: [:id], not_found_error?: false
      define :get_stock_for_item, args: [:item_id], not_found_error?: false
      define :create_stock, args: [:item]
      define :update_stock
      define :archive_stock
    end

    resource Loka.Inventory.Image do
      define :get_image, args: [:id], not_found_error?: false
      define :list_item_images, args: [:item_id]
      define :create_image, args: [:item_id, :file]
      define :delete_image
    end
  end
end

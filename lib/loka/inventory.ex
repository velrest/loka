defmodule Loka.Inventory do
  @moduledoc "Items studios sell, the stock offered for them, and their images."

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
      define :list_studio_items, args: [:studio_id]
      define :get_item, args: [:id], not_found_error?: false
      define :get_own_item, args: [:id], not_found_error?: false
      define :create_item
      define :update_item
      define :archive_item
    end

    resource Loka.Inventory.Stock do
      define :create_stock, args: [:item_id]
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

defmodule Inventory do
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
    resource Inventory.Item
  end
end

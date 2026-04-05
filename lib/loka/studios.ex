defmodule Loka.Studios do
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
    resource Loka.Studios.Studio do
      define :list_all_studios
      define :get_own_studio, not_found_error?: false
      define :create_studio
      define :update_studio
      define :archive_studio
    end
  end
end

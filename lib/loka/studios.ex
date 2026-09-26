defmodule Loka.Studios do
  @moduledoc "Pottery studios, each owned by a single user."

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
      define :get_studio, args: [:id], not_found_error?: false
      define :get_own_studio, not_found_error?: false
      define :create_studio
      define :update_studio
      define :archive_studio
      define :get_own_archived_studio, not_found_error?: false
      define :unarchive_studio
    end
  end
end

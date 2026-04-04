defmodule Loka.Studios do
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
    resource Loka.Studios.Studio
  end
end

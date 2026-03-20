defmodule Loka.Studios do
  use Ash.Domain,
    otp_app: :loka

  resources do
    resource Loka.Studios.Studio
  end
end

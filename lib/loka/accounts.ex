defmodule Loka.Accounts do
  use Ash.Domain, otp_app: :loka, extensions: [AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Loka.Accounts.Token
    resource Loka.Accounts.User
  end
end

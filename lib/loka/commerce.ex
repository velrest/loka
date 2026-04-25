defmodule Loka.Commerce do
  use Ash.Domain, otp_app: :loka, extensions: [AshPhoenix, AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Loka.Commerce.Cart do
      define :read_cart
    end

    resource Loka.Commerce.CartStock
  end
end

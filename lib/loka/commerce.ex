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

    resource Loka.Commerce.Order do
      define :list_user_orders
      define :get_order, args: [:id], not_found_error?: false
      define :place_order, args: [:lines]
    end

    resource Loka.Commerce.OrderLine
  end
end

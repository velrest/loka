defmodule Loka.Commerce do
  use Ash.Domain, otp_app: :loka, extensions: [AshPhoenix, AshAdmin.Domain]

  admin do
    show? true
  end

  resources do
    resource Loka.Commerce.Cart do
      define :get_user_cart, action: :for_user, not_found_error?: false
      define :get_anonymous_cart, action: :for_anonymous, args: [:id], not_found_error?: false

      define :create_cart, action: :create
      define :create_anonymous_cart, action: :create_anonymous

      define :ensure_cart_for_session, action: :ensure_for_session
      define :cleanup_anonymous, action: :cleanup_anonymous
      define :assign_to_user, action: :assign_to_user
      define :merge_from, action: :merge_from, args: [:anonymous_cart_id]
    end

    resource Loka.Commerce.CartStock do
      define :add_to_cart, action: :create, args: [:cart_id, :stock_id]
    end

    resource Loka.Commerce.Order do
      define :list_user_orders
      define :get_order, args: [:id], not_found_error?: false
      define :place_order, args: [:lines]
    end

    resource Loka.Commerce.OrderLine
  end
end

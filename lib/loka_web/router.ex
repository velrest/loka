defmodule LokaWeb.Router do
  use LokaWeb, :router

  import Oban.Web.Router
  use AshAuthentication.Phoenix.Router

  import AshAuthentication.Plug.Helpers

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LokaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :load_from_bearer
    plug :set_actor, :user
  end

  scope "/", LokaWeb do
    pipe_through :browser

    ash_authentication_live_session :authenticated_routes do
      # in each liveview, add one of the following at the top of the module:
      #
      # If an authenticated user must be present:
      # on_mount {LokaWeb.LiveUserAuth, :live_user_required}
      #
      # If an authenticated user *may* be present:
      # on_mount {LokaWeb.LiveUserAuth, :live_user_optional}
      #
      # If an authenticated user must *not* be present:
      # on_mount {LokaWeb.LiveUserAuth, :live_no_user}
      live "/", Shop.MarketLive
      live "/shop/item/:id", Shop.ItemLive
      live "/shop/studio/:id", Shop.StudioLive
      live "/shop/cart", Shop.CartLive

      live "/me/settings", User.SettingsLive
      live "/me/studio", User.StudioLive
      live "/me", User.ProfileLive

      live "/inventory/studio", Inventory.StudioLive
      live "/inventory/items", Inventory.ItemsLive
      live "/inventory/items/new", Inventory.ItemEditLive
      live "/inventory/items/:id", Inventory.ItemEditLive

      live "/about/", Shop.AboutLive
    end
  end

  scope "/", LokaWeb do
    pipe_through :browser

    # get "/", PageController, :home
    auth_routes AuthController, Loka.Accounts.User, path: "/auth"
    sign_out_route AuthController

    # Remove these if you'd like to use your own authentication views
    sign_in_route register_path: "/register",
                  reset_path: "/reset",
                  auth_routes_prefix: "/auth",
                  on_mount: [{LokaWeb.LiveUserAuth, :live_no_user}],
                  overrides: [
                    LokaWeb.AuthOverrides,
                    Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
                  ]

    # Remove this if you do not want to use the reset password feature
    reset_route auth_routes_prefix: "/auth",
                overrides: [
                  LokaWeb.AuthOverrides,
                  Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI
                ]

    # Remove this if you do not use the confirmation strategy
    confirm_route Loka.Accounts.User, :confirm_new_user,
      auth_routes_prefix: "/auth",
      overrides: [LokaWeb.AuthOverrides, Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI]

    # Remove this if you do not use the magic link strategy.
    magic_sign_in_route(Loka.Accounts.User, :magic_link,
      auth_routes_prefix: "/auth",
      overrides: [LokaWeb.AuthOverrides, Elixir.AshAuthentication.Phoenix.Overrides.DaisyUI]
    )
  end

  # Other scopes may use custom stacks.
  # scope "/api", LokaWeb do
  #   pipe_through :api
  # end

  # Admin tooling. Available in every environment, including production, but
  # only to users with the `admin?` flag.
  #
  # Two layers of enforcement, because these are LiveViews: `RequireAdmin`
  # guards the initial HTTP request, and the `:live_admin_required` on_mount
  # hook guards the LiveView websocket, which plugs never see.
  pipeline :admin do
    plug LokaWeb.Plugs.RequireAdmin
  end

  @admin_on_mount [{LokaWeb.LiveUserAuth, :live_admin_required}]

  scope "/" do
    pipe_through [:browser, :admin]

    import Phoenix.LiveDashboard.Router
    import AshAdmin.Router

    live_dashboard "/dashboard",
      metrics: LokaWeb.Telemetry,
      on_mount: @admin_on_mount

    oban_dashboard("/oban", on_mount: @admin_on_mount)

    ash_admin("/admin", on_mount: @admin_on_mount)
  end

  # Mailbox preview is a plain plug (no LiveView), and only makes sense where
  # mail is captured locally rather than actually delivered.
  if Application.compile_env(:loka, :dev_routes) do
    scope "/dev" do
      pipe_through [:browser, :admin]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

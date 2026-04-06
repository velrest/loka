# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Loka.Repo.insert!(%Loka.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Users
Ash.create!(
  Loka.Accounts.User,
  %{
    email: "user@loka.com",
    password: "password123",
    password_confirmation: "password123"
  },
  action: :register_with_password,
  authorize?: false
)

studio1_user =
  Ash.create!(
    Loka.Accounts.User,
    %{
      email: "studio1@loka.com",
      password: "password123",
      password_confirmation: "password123"
    },
    action: :register_with_password,
    authorize?: false
  )

studio2_user =
  Ash.create!(
    Loka.Accounts.User,
    %{
      email: "studio2@loka.com",
      password: "password123",
      password_confirmation: "password123"
    },
    action: :register_with_password,
    authorize?: false
  )

# Studios
studio1 =
  Loka.Studios.create_studio!(%{name: "Studio 1"}, actor: studio1_user, authorize?: false)

studio2 =
  Loka.Studios.create_studio!(%{name: "Studio 2"}, actor: studio2_user, authorize?: false)

# Stock for Studio 1 (items created inline via manage_relationship)
Loka.Inventory.create_stock!(
  %{name: "Pot", description: "The one pot"},
  studio1.id,
  %{quantity: 12, price: Money.new(:CHF, "1000")},
  actor: studio1_user,
  authorize?: false
)

Loka.Inventory.create_stock!(
  %{name: "Bowl", description: "The one Bowl"},
  studio1.id,
  %{quantity: 4, price: Money.new(:CHF, "500")},
  actor: studio1_user,
  authorize?: false
)

# Stock for Studio 2
Loka.Inventory.create_stock!(
  %{name: "Mug", description: "The generic mug"},
  studio2.id,
  %{quantity: 100, price: Money.new(:CHF, "5")},
  actor: studio2_user,
  authorize?: false
)

Loka.Inventory.create_stock!(
  %{name: "Plate", description: "The generic plate"},
  studio2.id,
  %{quantity: 150, price: Money.new(:CHF, "10")},
  actor: studio2_user,
  authorize?: false
)

Loka.Inventory.create_stock!(
  %{name: "Vase", description: "The generic Vase"},
  studio2.id,
  %{quantity: 30, price: Money.new(:CHF, "50")},
  actor: studio2_user,
  authorize?: false
)

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
{:ok, _user} =
  Ash.create(Loka.Accounts.User, %{
    email: "user@loka.com",
    password: "password123",
    password_confirmation: "password123"
  }, action: :register_with_password, authorize?: false)

{:ok, studio1_user} =
  Ash.create(Loka.Accounts.User, %{
    email: "studio1@loka.com",
    password: "password123",
    password_confirmation: "password123"
  }, action: :register_with_password, authorize?: false)

{:ok, studio2_user} =
  Ash.create(Loka.Accounts.User, %{
    email: "studio2@loka.com",
    password: "password123",
    password_confirmation: "password123"
  }, action: :register_with_password, authorize?: false)

# Studios
Ash.create!(Loka.Studios.Studio, %{name: "Studio 1"},
  action: :create_studio, actor: studio1_user, authorize?: false)

Ash.create!(Loka.Studios.Studio, %{name: "Studio 2"},
  action: :create_studio, actor: studio2_user, authorize?: false)

# Stock for Studio 1 (items created inline via manage_relationship)
Ash.create!(Loka.Inventory.Stock, %{
  quantity: 12,
  price: Money.new(:CHF, "1000"),
  item: %{name: "Pot", description: "The one pot"}
}, action: :create_stock, actor: studio1_user, authorize?: false)

Ash.create!(Loka.Inventory.Stock, %{
  quantity: 4,
  price: Money.new(:CHF, "500"),
  item: %{name: "Bowl", description: "The one Bowl"}
}, action: :create_stock, actor: studio1_user, authorize?: false)

# Stock for Studio 2
Ash.create!(Loka.Inventory.Stock, %{
  quantity: 100,
  price: Money.new(:CHF, "5"),
  item: %{name: "Mug", description: "The generic mug"}
}, action: :create_stock, actor: studio2_user, authorize?: false)

Ash.create!(Loka.Inventory.Stock, %{
  quantity: 150,
  price: Money.new(:CHF, "10"),
  item: %{name: "Plate", description: "The generic plate"}
}, action: :create_stock, actor: studio2_user, authorize?: false)

Ash.create!(Loka.Inventory.Stock, %{
  quantity: 30,
  price: Money.new(:CHF, "50"),
  item: %{name: "Vase", description: "The generic Vase"}
}, action: :create_stock, actor: studio2_user, authorize?: false)

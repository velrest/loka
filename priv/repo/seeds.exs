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
  Loka.Studios.create_studio!(%{name: "Studio 1", city: "Zürich", postal_code: "8001"}, actor: studio1_user, authorize?: false)

studio2 =
  Loka.Studios.create_studio!(%{name: "Studio 2", city: "Bern", postal_code: "3004"}, actor: studio2_user, authorize?: false)

# Stock for Studio 1 (items created inline via manage_relationship)
Loka.Inventory.create_stock!(
  %{
    name: "Pot",
    description:
      "Handgedrehter Vorratstopf aus lokaler Steinzeugmasse. Die natürliche Glasur mit sanften Aschespuren verleiht jedem Stück seinen einzigartigen Charakter. Ideal für Kräuter, Salz oder als dekoratives Objekt auf der Fensterbank."
  },
  %{quantity: 12, price: Money.new(:CHF, "1000")},
  actor: studio1_user,
  authorize?: false
)

Loka.Inventory.create_stock!(
  %{
    name: "Bowl",
    description:
      "Grosszügige Servierschüssel mit weich ausgeformtem Rand. Von Hand gedreht und mit einer matten Seladonglasur veredelt – jedes Stück ein Unikat für den gedeckten Tisch. Spülmaschinenfest, aber zu schön dafür."
  },
  %{quantity: 4, price: Money.new(:CHF, "500")},
  actor: studio1_user,
  authorize?: false
)

# Stock for Studio 2
Loka.Inventory.create_stock!(
  %{
    name: "Mug",
    description:
      "Ein handlicher Becher aus Steinzeug, der in der Hand liegt wie gemacht. Die leicht unregelmässige Form erinnert daran, dass hier kein Roboter am Werk war. Für Morgenkaffee, Tee oder einfach stilles Halten."
  },
  %{quantity: 100, price: Money.new(:CHF, "5")},
  actor: studio2_user,
  authorize?: false
)

Loka.Inventory.create_stock!(
  %{
    name: "Plate",
    description:
      "Flacher Speiseteller mit sorgfältig gezogenem Rand. Die raue Unterseite und die glatte, glasierte Oberfläche setzen jedes Gericht in Szene. Stapelbar, robust, und trotzdem eine Freude zu benutzen."
  },
  %{quantity: 150, price: Money.new(:CHF, "10")},
  actor: studio2_user,
  authorize?: false
)

Loka.Inventory.create_stock!(
  %{
    name: "Vase",
    description:
      "Schlanke Vase aus Steinzeug, von Hand geformt und bei hoher Temperatur gebrannt. Perfekt für einen einzelnen Zweig, eine Wildblume oder als stiller Hingucker auf dem Sideboard. Jedes Stück trägt die Spuren seiner Entstehung."
  },
  %{quantity: 30, price: Money.new(:CHF, "50")},
  actor: studio2_user,
  authorize?: false
)

# Add multiple images to Pot and Mug to demo the image slider
priv = to_string(:code.priv_dir(:loka))

seed_images = fn item_id, filenames ->
  for filename <- filenames do
    src = Path.join([priv, "static", "images", "seed", filename])
    {:ok, ash_file} = Ash.Type.File.cast_input(%Plug.Upload{path: src, filename: filename, content_type: "image/svg+xml"}, [])
    result = Loka.Inventory.create_image!(item_id, ash_file, authorize?: false)
    dest = Path.join([priv, "static", String.trim_leading(result.path, "/")])
    File.mkdir_p!(Path.dirname(dest))
    File.cp!(src, dest)
  end
end

stocks = Loka.Inventory.list_all_stock!(load: :item)

item_images = %{
  "Pot" => ~w[pottery-1.svg pottery-2.svg pottery-3.svg],
  "Bowl" => ~w[bowl.svg],
  "Mug" => ~w[pottery-2.svg pottery-3.svg],
  "Plate" => ~w[plate.svg],
  "Vase" => ~w[vase.svg]
}

Enum.each(stocks, fn stock ->
  case Map.get(item_images, stock.item.name) do
    nil -> :ok
    filenames -> seed_images.(stock.item_id, filenames)
  end
end)

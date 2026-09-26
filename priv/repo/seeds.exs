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

# Users (all with password "password123")
register = fn email ->
  Ash.create!(
    Loka.Accounts.User,
    %{email: email, password: "password123", password_confirmation: "password123"},
    action: :register_with_password,
    authorize?: false
  )
end

# admin? isn't writable through any action, so it's set out of band
"admin@example.com" |> register.() |> Ash.Seed.update!(%{admin?: true})
register.("user@example.com")

# Studios, each with its own owner. The login is <city>@example.com, or
# <city><n>@example.com when a city has several studios.
studios = [
  {"solothurn", "Töpferei an der Aare", "Solothurn", "4500"},
  {"biel", "Atelier Terre", "Biel/Bienne", "2502"},
  {"grenchen", "Keramik Grenchen", "Grenchen", "2540"},
  {"lengnau", "Tonwerk Lengnau", "Lengnau", "2543"},
  {"worb", "Brennofen Worb", "Worb", "3076"},
  {"bern1", "Lauben Keramik", "Bern", "3004"},
  {"bern2", "Atelier Matte", "Bern", "3011"},
  {"bern3", "Scherben & Glasur", "Bern", "3013"},
  {"zurich1", "Drehscheibe Zürich", "Zürich", "8001"},
  {"zurich2", "Studio Limmat", "Zürich", "8003"},
  {"zurich3", "Tonstube", "Zürich", "8004"},
  {"zurich4", "Keramikwerk Kreis 5", "Zürich", "8005"},
  {"zurich5", "Atelier Wipkingen", "Zürich", "8037"},
  {"zurich6", "Erde & Feuer", "Zürich", "8044"}
]

owners =
  Map.new(studios, fn {login, name, city, postal_code} ->
    owner = register.("#{login}@example.com")

    Loka.Studios.create_studio!(%{name: name, city: city, postal_code: postal_code},
      actor: owner,
      authorize?: false
    )

    {login, owner}
  end)

# Items
#
# Each studio sells a run of pieces from this catalogue, in its own signature
# glaze. Studios in the larger cities carry more pieces than the remote ones.
catalogue = [
  {"Vorratstopf",
   "Handgedrehter Vorratstopf aus lokaler Steinzeugmasse. Die natürliche Glasur verleiht jedem Stück seinen einzigartigen Charakter. Ideal für Kräuter, Salz oder als dekoratives Objekt auf der Fensterbank.",
   68, ~w[pottery-1.svg pottery-2.svg pottery-3.svg]},
  {"Servierschüssel",
   "Grosszügige Servierschüssel mit weich ausgeformtem Rand. Von Hand gedreht – jedes Stück ein Unikat für den gedeckten Tisch. Spülmaschinenfest, aber zu schön dafür.",
   85, ~w[bowl.svg]},
  {"Becher",
   "Ein handlicher Becher aus Steinzeug, der in der Hand liegt wie gemacht. Die leicht unregelmässige Form erinnert daran, dass hier kein Roboter am Werk war. Für Morgenkaffee, Tee oder einfach stilles Halten.",
   32, ~w[mug.svg]},
  {"Speiseteller",
   "Flacher Speiseteller mit sorgfältig gezogenem Rand. Die raue Unterseite und die glatte, glasierte Oberfläche setzen jedes Gericht in Szene. Stapelbar, robust, und trotzdem eine Freude zu benutzen.",
   42, ~w[plate.svg]},
  {"Vase",
   "Schlanke Vase aus Steinzeug, von Hand geformt und bei hoher Temperatur gebrannt. Perfekt für einen einzelnen Zweig, eine Wildblume oder als stiller Hingucker auf dem Sideboard.",
   74, ~w[vase.svg]},
  {"Espressotasse",
   "Kleine Tasse mit Untertasse für den kurzen Schwarzen. Dickwandig, damit der Espresso heiss bleibt, und mit einem Henkel, der auch grössere Finger nicht im Stich lässt.",
   28, ~w[espresso-cup.svg]},
  {"Teekanne",
   "Bauchige Teekanne für vier Tassen, mit tropffreiem Ausguss und gut sitzendem Deckel. Die dicken Wände halten den Tee lange warm.",
   120, ~w[teapot.svg]},
  {"Krug",
   "Hoher Krug für Wasser, Milch oder einen Strauss Gartenblumen. Der gezogene Ausguss giesst sauber, der breite Henkel liegt sicher in der Hand.",
   78, ~w[pitcher.svg]},
  {"Nudelschale",
   "Tiefe Schale für Ramen, Suppen und Eintöpfe. Genug Platz für Brühe, Nudeln und alles, was dazugehört – und angenehm warm in beiden Händen.",
   48, ~w[noodle-bowl.svg]},
  {"Blumentopf",
   "Blumentopf mit Abzugsloch und passendem Untersetzer. Unglasiert an der Innenseite, damit die Erde atmen kann – für Kräuter auf dem Balkon oder die Zimmerpflanze.",
   55, ~w[planter.svg]},
  {"Kerzenhalter",
   "Schlichter Kerzenhalter für Stabkerzen. Die breite Schale fängt Wachs auf und steht stabil auf Tisch und Fensterbrett.",
   36, ~w[candle-holder.svg]},
  {"Ölflasche",
   "Bauchige Flasche für Olivenöl oder Essig, mit Korkzapfen. Die Glasur ist innen dicht und lässt sich gut reinigen.",
   46, ~w[oil-bottle.svg]},
  {"Servierplatte",
   "Ovale Platte für Antipasti, Käse oder den Sonntagsbraten. Mit Pinselstrichen von Hand bemalt, jede Platte ein wenig anders.",
   95, ~w[platter.svg]},
  {"Schälchen-Set",
   "Drei kleine Schälchen für Dips, Oliven, Nüsse oder Salz. In drei Farben glasiert, ineinander stapelbar.",
   39, ~w[small-dishes.svg]},
  {"Müslischale",
   "Handliche Schale für Müesli, Joghurt oder Porridge. Mit einem farbigen Band unter dem Rand und einem Standring, der gut in der Hand liegt.",
   34, ~w[cereal-bowl.svg]},
  {"Butterdose",
   "Butterdose mit Glocke, die die Butter streichzart und geschützt hält. Passt auf jeden Frühstückstisch.",
   58, ~w[butter-dish.svg]}
]

# {studio login, signature glaze, number of pieces}
assortments = [
  {"zurich1", "Seladon", 10},
  {"zurich2", "Tenmoku", 9},
  {"zurich3", "Shino", 10},
  {"zurich4", "Kobaltblau", 9},
  {"zurich5", "Aschenglasur", 10},
  {"zurich6", "Rostrot", 9},
  {"bern1", "Milchweiss", 9},
  {"bern2", "Moosgrün", 8},
  {"bern3", "Nachtblau", 8},
  {"biel", "Ocker", 7},
  {"solothurn", "Salzglasur", 7},
  {"grenchen", "Kupferrot", 6},
  {"worb", "Sandstein", 5},
  {"lengnau", "Rauchbrand", 5}
]

# A few Bern items get oddly sized images first, to check that product cards
# and the image slider always render images in the same format.
# {studio login, piece index} => images shown before the regular ones
odd_images = %{
  {"bern1", 0} => ~w[test-wide.svg],
  {"bern1", 1} => ~w[test-tiny.png],
  {"bern2", 0} => ~w[test-tall.svg],
  {"bern2", 1} => ~w[test-huge.png],
  {"bern3", 0} => ~w[test-tiny.svg test-wide.svg test-tall.svg test-tiny.png test-huge.png]
}

priv = to_string(:code.priv_dir(:loka))

seed_images = fn item_id, filenames ->
  for filename <- filenames do
    src = Path.join([priv, "static", "images", "seed", filename])

    {:ok, ash_file} =
      Ash.Type.File.cast_input(
        %Plug.Upload{path: src, filename: filename, content_type: MIME.from_path(filename)},
        []
      )

    Loka.Inventory.create_image!(item_id, ash_file, authorize?: false)
  end
end

catalogue_size = length(catalogue)

assortments
|> Enum.with_index()
|> Enum.each(fn {{login, glaze, count}, studio_index} ->
  owner = owners[login]

  # Start each studio at a different point in the catalogue so neighbouring
  # studios don't all sell the same things
  for n <- 0..(count - 1) do
    {name, description, base_price, images} =
      Enum.at(catalogue, rem(studio_index * 5 + n, catalogue_size))

    # Prices vary a little between studios: -10% to +10%, whole francs
    price = round(base_price * (0.9 + rem(studio_index * 3 + n, 5) * 0.05))
    quantity = 2 + rem(studio_index * 7 + n * 3, 14)

    stock =
      Loka.Inventory.create_stock!(
        %{name: "#{name} #{glaze}", description: description},
        %{quantity: quantity, price: Money.new(:CHF, price)},
        actor: owner,
        authorize?: false
      )

    seed_images.(stock.item_id, Map.get(odd_images, {login, n}, []) ++ images)
  end
end)

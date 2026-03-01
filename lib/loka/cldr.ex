defmodule Loka.Cldr do
  use Cldr,
    locales: ["de-CH", "fr-CH"],
    providers: [Cldr.Number, Cldr.Calendar, Cldr.DateTime]
end

defmodule Loka.Studios.Studio.Changes.GeocodeAddress do
  use Ash.Resource.Change

  def change(changeset, _opts, _context) do
    case Ash.Changeset.get_attribute(changeset, :postal_code) do
      nil ->
        changeset

      plz ->
        case Loka.Address.Localities.coordinates_for_postal_code(plz) do
          {lat, lon} ->
            changeset
            |> Ash.Changeset.change_attribute(:latitude, lat)
            |> Ash.Changeset.change_attribute(:longitude, lon)

          nil ->
            changeset
        end
    end
  end
end

defmodule Loka.Address.Localities do
  @csv_path Path.join(:code.priv_dir(:loka), "data/localities.csv")
  @external_resource @csv_path

  @localities (
    @csv_path
    |> File.stream!(encoding: :utf8)
    |> Stream.drop(1)
    |> Enum.map(fn line ->
      parts = String.split(String.trim(line), ";")
      {Enum.at(parts, 0), Enum.at(parts, 1), Enum.at(parts, 8), Enum.at(parts, 9)}
    end)
  )

  def search(query) when byte_size(query) < 2, do: []

  def search(query) do
    q = String.downcase(query)

    @localities
    |> Enum.filter(fn {name, plz, _, _} ->
      String.starts_with?(String.downcase(name), q) or String.starts_with?(plz, query)
    end)
    |> Enum.take(10)
    |> Enum.map(fn {name, plz, _, _} -> %{city: name, zip: plz} end)
  end

  def coordinates_for_postal_code(plz) do
    case Enum.find(@localities, fn {_, p, _, _} -> p == plz end) do
      {_, _, e_str, n_str} -> lv95_to_wgs84(parse_float(e_str), parse_float(n_str))
      nil -> nil
    end
  end

  defp parse_float(str) do
    case Float.parse(str) do
      {f, _} -> f
      :error -> nil
    end
  end

  defp lv95_to_wgs84(nil, _), do: nil
  defp lv95_to_wgs84(_, nil), do: nil

  defp lv95_to_wgs84(e, n) do
    y = (e - 2_600_000) / 1_000_000
    x = (n - 1_200_000) / 1_000_000
    lon = (2.6779094 + 4.728982 * y + 0.791484 * y * x + 0.1306 * y * x * x - 0.0436 * y * y * y) * 100 / 36
    lat = (16.9023892 + 3.238272 * x - 0.270978 * y * y - 0.002528 * x * x - 0.0447 * y * y * x - 0.0140 * x * x * x) * 100 / 36
    {lat, lon}
  end
end

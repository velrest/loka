defmodule Loka.Address.Localities do
  @csv_path Path.join(:code.priv_dir(:loka), "data/localities.csv")
  @external_resource @csv_path

  @localities (
    @csv_path
    |> File.stream!(encoding: :utf8)
    |> Stream.drop(1)
    |> Enum.map(fn line ->
      [name, plz | _] = String.split(String.trim(line), ";")
      {name, plz}
    end)
  )

  def search(query) when byte_size(query) < 2, do: []

  def search(query) do
    q = String.downcase(query)

    @localities
    |> Enum.filter(fn {name, plz} ->
      String.starts_with?(String.downcase(name), q) or String.starts_with?(plz, query)
    end)
    |> Enum.take(10)
    |> Enum.map(fn {name, plz} -> %{city: name, zip: plz} end)
  end
end

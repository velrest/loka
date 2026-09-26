defmodule Loka.Support.InventoryHelpers do
  @moduledoc false

  @default_stock %{quantity: 10, price: Money.new(:CHF, 500)}

  @doc """
  Creates an item in the owner's studio, on sale with `@default_stock` unless
  `:stock` is given (pass `stock: nil` for an item that isn't on sale).
  Returns it with stock, studio, images and `in_stock?` loaded.
  """
  def create_item(owner, attrs \\ %{}) do
    %{name: "Widget", description: "A widget", stock: @default_stock}
    |> Map.merge(attrs)
    |> Loka.Inventory.create_item!(actor: owner)
    |> Ash.load!([:stock, :studio, :images, :in_stock?])
  end
end

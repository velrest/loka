defmodule Loka.Checks.ActorHasStudio do
  use Ash.Policy.SimpleCheck

  def describe(_opts), do: "actor owns a studio"

  def match?(nil, _context, _opts), do: false

  def match?(actor, _context, _opts) do
    actor = Ash.load!(actor, :studio)
    not is_nil(actor.studio)
  end
end

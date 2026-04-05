defmodule Loka.Checks.ActorHasStudio do
  use Ash.Policy.SimpleCheck

  def describe(_opts), do: "actor owns a studio"

  def match?(nil, _context, _opts), do: false

  def match?(actor, _context, _opts) do
    case Loka.Studios.get_own_studio(actor: actor) do
      {:ok, studio} when not is_nil(studio) -> true
      _ -> false
    end
  end
end

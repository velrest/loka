defmodule LokaWeb.Locale do
  @moduledoc """
  The locales this app supports, shared by `LokaWeb.Plugs.SetLocale` (HTTP)
  and `LokaWeb.LiveLocale` (LiveView) so both stay in sync.

  German has no `priv/gettext/de` catalog — the `gettext(...)` calls in
  templates are already German, so untranslated msgids render correctly as
  the default. Only "en" has an actual translation catalog.
  """

  @locales ["de", "en"]
  @default "de"

  def locales, do: @locales
  def default, do: @default
end

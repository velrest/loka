defmodule LokaWeb.Plugs.SetLocale do
  @moduledoc """
  Reads the desired locale from the `locale` query param (falling back to
  whatever was chosen last, stored in the session), applies it via
  `Gettext.put_locale/1` for the current request, and persists the choice.

  `Gettext.put_locale/1` sets the locale for every registered Gettext
  backend in the process — including Ash's own (once `mix ash.gen.gettext`
  has been run), not just `LokaWeb.Gettext`.
  """
  import Plug.Conn

  @locales LokaWeb.Locale.locales()
  @default LokaWeb.Locale.default()

  def init(default), do: default

  def call(conn, _opts) do
    locale =
      (conn.params["locale"] || get_session(conn, :locale) || @default)
      |> then(&if &1 in @locales, do: &1, else: @default)

    Gettext.put_locale(locale)
    put_session(conn, :locale, locale)
  end
end

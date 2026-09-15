defmodule LokaWeb.LiveLocale do
  @moduledoc """
  Re-applies the session's chosen locale inside the LiveView process.

  Gettext's locale lives in the process dictionary, and a connected
  LiveView mount runs in a different process than the initial HTTP
  request that `LokaWeb.Plugs.SetLocale` ran in, so it has to be set again
  here. Assigns `:locale` so templates (the nav bar's DE/EN toggle) can
  show which one is active.
  """
  import Phoenix.Component, only: [assign: 3]

  @locales LokaWeb.Locale.locales()
  @default LokaWeb.Locale.default()

  def on_mount(:default, _params, session, socket) do
    locale =
      (session["locale"] || @default)
      |> then(&if &1 in @locales, do: &1, else: @default)

    Gettext.put_locale(locale)
    {:cont, assign(socket, :locale, locale)}
  end
end

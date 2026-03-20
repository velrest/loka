defmodule LokaWeb.Utils.AssignCurrentPath do
  import Phoenix.LiveView, only: [on_mount: 4, attach_hook: 4]
  import Phoenix.Component, only: [assign: 2]

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     attach_hook(socket, :assign_current_path, :handle_params, fn _params, uri, socket ->
       {:cont, assign(socket, current_path: URI.parse(uri).path)}
     end)}
  end
end

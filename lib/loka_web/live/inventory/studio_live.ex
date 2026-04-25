defmodule LokaWeb.Inventory.StudioLive do
  use LokaWeb, :live_view

  on_mount {LokaWeb.LiveUserAuth, :live_user_required}

  @impl true
  def mount(_params, _session, socket) do
    case Loka.Studios.get_own_studio(actor: socket.assigns.current_user) do
      {:ok, nil} ->
        {:ok, push_navigate(socket, to: ~p"/me/studio")}

      {:ok, studio} ->
        form =
          Loka.Studios.form_to_update_studio(
            studio,
            actor: socket.assigns.current_user,
            as: "studio"
          )
          |> to_form()

        {:ok, assign(socket, studio: studio, form: form, saved: false, show_confirm: false)}
    end
  end

  @impl true
  def handle_info(:clear_saved, socket) do
    {:noreply, assign(socket, saved: false)}
  end

  @impl true
  def handle_event("request_delete", _params, socket) do
    {:noreply, assign(socket, show_confirm: true)}
  end

  def handle_event("cancel_delete", _params, socket) do
    {:noreply, assign(socket, show_confirm: false)}
  end

  def handle_event("delete", _params, socket) do
    case Loka.Studios.archive_studio(socket.assigns.studio, actor: socket.assigns.current_user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Studio deleted."))
         |> push_navigate(to: ~p"/me/studio")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Could not delete studio."))
         |> assign(show_confirm: false)}
    end
  end

  @impl true
  def handle_event("validate", _params, %{assigns: %{form: nil}} = socket),
    do: {:noreply, socket}

  def handle_event("validate", params, socket) do
    form = AshPhoenix.Form.validate(socket.assigns.form.source, params["studio"] || %{})
    {:noreply, assign(socket, form: to_form(form))}
  end

  @impl true
  def handle_event("save", _params, %{assigns: %{form: nil}} = socket),
    do: {:noreply, socket}

  def handle_event("save", params, socket) do
    case AshPhoenix.Form.submit(socket.assigns.form.source, params: params["studio"] || %{}) do
      {:ok, studio} ->
        form =
          AshPhoenix.Form.for_update(studio, :update_studio,
            actor: socket.assigns.current_user,
            as: "studio"
          )
          |> to_form()

        Process.send_after(self(), :clear_saved, 2000)

        {:noreply,
         socket
         |> put_flash(:info, gettext("Studio saved successfully."))
         |> assign(studio: studio, form: form, saved: true)}

      {:error, form} ->
        {:noreply, assign(socket, form: to_form(form))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app current_user={@current_user} flash={@flash}>
      <:nav>
        <.inventory_tab_nav active={@current_path} />
      </:nav>

      <div class="px-4 py-10 sm:px-6 lg:px-8 max-w-sm">
        <.header>{gettext("Manage your studio")}</.header>

        <.form
          for={@form}
          phx-change="validate"
          phx-submit="save"
          class="mt-6 flex flex-col gap-4"
        >
          <.input field={@form[:name]} type="text" label={gettext("Studio name")} />
          <.button type="submit" class={["btn btn-primary", @saved && "btn-success"]}>
            <.icon :if={@saved} name="hero-check" class="size-4" />
            {if @saved, do: gettext("Saved!"), else: gettext("Update studio")}
          </.button>
        </.form>

        <div class="mt-12 border-t border-error/20 pt-6">
          <.button phx-click="request_delete" class="btn btn-outline btn-error btn-sm">
            {gettext("Archive studio")}
          </.button>
        </div>
      </div>

      <dialog class={["modal", @show_confirm && "modal-open"]}>
        <div class="modal-box">
          <h3 class="text-lg font-bold">{gettext("Archive your studio?")}</h3>
          <p class="py-4 text-base-content/70">
            {gettext(
              "Your studio will be archived and no longer visible to you or customers. Your data is retained and can be restored by contacting support."
            )}
          </p>
          <div class="modal-action">
            <.button phx-click="cancel_delete" class="btn btn-ghost">
              {gettext("Cancel")}
            </.button>
            <.button phx-click="delete" class="btn btn-error">
              {gettext("Yes, archive")}
            </.button>
          </div>
        </div>
        <div class="modal-backdrop" phx-click="cancel_delete" />
      </dialog>
    </Layouts.app>
    """
  end
end

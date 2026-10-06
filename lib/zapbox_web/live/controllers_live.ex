defmodule ZapboxWeb.ControllersLive do
  use ZapboxWeb, :live_view
  alias Zapbox.Controllers
  alias Zapbox.Controllers.Controller

  def mount(params, _session, socket) do
    {controller, editing} =
      case params do
        %{"id" => id} ->
          {case Controllers.get_controller(id) do
             {:ok, c} -> c
             :error -> blank(%{})
           end, true}

        %{"phone_id" => _} ->
          {blank(params), true}

        _ ->
          {blank(%{}), false}
      end

    {:ok,
     assign(socket,
       controllers: Controllers.list_controllers(),
       form_controller: controller,
       errors: %{},
       editing: editing
     )}
  end

  def handle_event("save", %{"controller" => attrs}, socket) do
    operation =
      if socket.assigns.editing && socket.assigns.form_controller.id != "",
        do: Controllers.update_controller(socket.assigns.form_controller, attrs),
        else: Controllers.create_controller(attrs)

    case operation do
      {:ok, _} ->
        {:noreply,
         socket |> put_flash(:info, "Controller saved") |> push_navigate(to: ~p"/controllers")}

      {:error, errors} ->
        {:noreply,
         assign(socket,
           form_controller: apply_attrs(socket.assigns.form_controller, attrs),
           errors: errors
         )}
    end
  end

  def handle_event("edit", %{"id" => id}, socket),
    do: {:noreply, push_navigate(socket, to: ~p"/controllers/#{id}/edit")}

  def handle_event("new", _, socket),
    do: {:noreply, push_navigate(socket, to: ~p"/controllers/new")}

  def handle_event("delete", %{"id" => id}, socket),
    do:
      (
        Controllers.delete_controller(id)
        {:noreply, assign(socket, controllers: Controllers.list_controllers())}
      )

  def handle_event("toggle", %{"id" => id}, socket) do
    {:ok, c} = Controllers.get_controller(id)
    {:ok, _} = Controllers.update_controller(c, %{enabled: !c.enabled})
    {:noreply, assign(socket, controllers: Controllers.list_controllers())}
  end

  defp blank(params),
    do: %Controller{
      id: "",
      name: "",
      phone_id: params["phone_id"] || "",
      description: nil,
      enabled: true,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }

  defp apply_attrs(c, attrs),
    do: %{
      c
      | name: attrs["name"] || c.name,
        phone_id: attrs["phone_id"] || c.phone_id,
        description: attrs["description"] || c.description,
        enabled: attrs["enabled"] == "true"
    }
end

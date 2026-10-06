defmodule ZapboxWeb.InboxLive do
  use ZapboxWeb, :live_view
  alias Zapbox.{Controllers, Messages}

  @tabs ["preview", "payload", "headers", "response"]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Messages.subscribe()
    messages = Messages.list()

    {:ok,
     assign(socket,
       messages: messages,
       selected: List.first(messages),
       query: "",
       tab: "preview",
       controllers: Controllers.list_controllers(),
       controller_filter: "all"
     )}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    messages =
      filter(Messages.list(), query, socket.assigns.controller_filter, socket.assigns.controllers)

    selected =
      if socket.assigns.selected && Enum.any?(messages, &(&1.id == socket.assigns.selected.id)),
        do: socket.assigns.selected,
        else: List.first(messages)

    {:noreply, assign(socket, messages: messages, selected: selected, query: query)}
  end

  def handle_event("filter_controller", %{"controller" => controller_filter}, socket) do
    messages =
      filter(Messages.list(), socket.assigns.query, controller_filter, socket.assigns.controllers)

    {:noreply,
     assign(socket,
       messages: messages,
       selected: List.first(messages),
       controller_filter: controller_filter
     )}
  end

  def handle_event("select", %{"id" => id}, socket) do
    {:ok, message} = Messages.get(id)
    {:noreply, assign(socket, selected: message)}
  end

  def handle_event("tab", %{"tab" => tab}, socket) when tab in @tabs,
    do: {:noreply, assign(socket, tab: tab)}

  def handle_event("register_controller", _, socket),
    do:
      {:noreply,
       push_navigate(socket,
         to: ~p"/controllers/new?phone_id=#{socket.assigns.selected.phone_id}"
       )}

  @impl true
  def handle_info({:message_received, message}, socket) do
    controllers = Controllers.list_controllers()

    messages =
      filter(Messages.list(), socket.assigns.query, socket.assigns.controller_filter, controllers)

    {:noreply,
     assign(socket,
       messages: messages,
       selected: socket.assigns.selected || message,
       controllers: controllers
     )}
  end

  defp filter(messages, query, controller_filter, controllers) do
    needle = query |> String.trim() |> String.downcase()

    messages =
      if needle == "",
        do: messages,
        else:
          Enum.filter(messages, fn m ->
            Enum.any?(
              [m.to, m.template_name, m.message_type],
              &String.contains?(String.downcase(&1 || ""), needle)
            )
          end)

    Enum.filter(messages, fn message ->
      case controller_filter do
        "all" -> true
        "unknown" -> !Enum.any?(controllers, &(&1.phone_id == message.phone_id))
        id -> Enum.any?(controllers, &(&1.id == id && &1.phone_id == message.phone_id))
      end
    end)
  end

  defp controller_for(message, controllers),
    do: Enum.find(controllers, &(&1.phone_id == message.phone_id))

  defp relative_time(time) do
    seconds = max(DateTime.diff(DateTime.utc_now(), time), 0)

    cond do
      seconds < 60 -> "just now"
      seconds < 3_600 -> "#{div(seconds, 60)} min"
      seconds < 86_400 -> "#{div(seconds, 3_600)} h"
      true -> "#{div(seconds, 86_400)} d"
    end
  end

  defp json(value), do: Jason.encode!(value, pretty: true)
  defp components(message), do: get_in(message.request_body, ["template", "components"]) || []

  defp params_for(message, type),
    do:
      components(message)
      |> Enum.filter(&(String.downcase(&1["type"] || "") == type))
      |> Enum.flat_map(&(&1["parameters"] || []))

  defp button_components(message),
    do: components(message) |> Enum.filter(&(String.downcase(&1["type"] || "") == "button"))

  defp param_value(%{"text" => value}), do: value
  defp param_value(%{"payload" => value}), do: value
  defp param_value(%{"url" => value}), do: value
  defp param_value(value), do: json(value)
end

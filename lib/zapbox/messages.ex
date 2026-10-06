defmodule Zapbox.Messages do
  @moduledoc "Domain API for captured WhatsApp Cloud API messages."

  alias Zapbox.Messages.{Message, Store}

  @topic "messages"

  def topic, do: @topic

  def subscribe, do: Phoenix.PubSub.subscribe(Zapbox.PubSub, @topic)

  def list, do: Store.list()

  def get(id), do: Store.get(id)

  def capture(version, phone_id, body, headers) do
    id = unique_id()
    wa_id = "wamid.zapbox_" <> id
    to = Map.get(body, "to")
    response = response(to, wa_id)
    template = Map.get(body, "template", %{})

    message = %Message{
      id: id,
      wa_message_id: wa_id,
      api_version: version,
      phone_id: phone_id,
      to: to,
      recipient_type: Map.get(body, "recipient_type"),
      message_type: Map.get(body, "type"),
      template_name: Map.get(template, "name"),
      language: get_in(template, ["language", "code"]),
      request_body: body,
      request_headers: sanitize_headers(headers),
      response_body: response,
      response_status: 200,
      inserted_at: DateTime.utc_now()
    }

    :ok = Store.insert(message)
    Phoenix.PubSub.broadcast(Zapbox.PubSub, @topic, {:message_received, message})
    {message, response}
  end

  defp response(to, wa_id) do
    digits = to |> to_string_safe() |> String.replace(~r/\D/, "")

    %{
      "messaging_product" => "whatsapp",
      "contacts" => [%{"input" => to, "wa_id" => digits}],
      "messages" => [%{"id" => wa_id}]
    }
  end

  defp to_string_safe(nil), do: ""
  defp to_string_safe(value), do: to_string(value)

  defp unique_id,
    do: Base.encode32(:crypto.strong_rand_bytes(10), padding: false) |> String.downcase()

  defp sanitize_headers(headers) do
    Enum.map(headers, fn {name, value} ->
      {name, sanitized_header_value(name, value)}
    end)
  end

  defp sanitized_header_value(name, _value)
       when name in ["authorization", "proxy-authorization", "cookie", "set-cookie"],
       do: "********"

  defp sanitized_header_value(_name, value), do: value
end

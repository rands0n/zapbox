defmodule Zapbox.Controllers do
  @moduledoc "Local metadata for WhatsApp senders known by Zapbox."

  alias Zapbox.Controllers.{Controller, Store}

  def list_controllers, do: Store.list()

  def get_controller(id), do: Store.get(id)

  def get_by_phone_id(phone_id), do: Store.get_by_phone_id(normalize_phone_id(phone_id))

  def delete_controller(%Controller{id: id}), do: Store.delete(id)

  def delete_controller(id), do: Store.delete(id)

  def create_controller(attrs) do
    now = DateTime.utc_now()

    controller = %Controller{
      id: id(),
      inserted_at: now,
      updated_at: now,
      name: "",
      phone_id: "",
      enabled: true
    }

    build_and_save(controller, attrs, :create)
  end

  def update_controller(%Controller{} = controller, attrs),
    do: build_and_save(controller, attrs, :update)

  defp build_and_save(controller, attrs, action) do
    now = DateTime.utc_now()

    controller = %{
      controller
      | name: trim(attrs["name"] || attrs[:name] || controller.name),
        phone_id:
          normalize_phone_id(attrs["phone_id"] || attrs[:phone_id] || controller.phone_id),
        description:
          blank_nil(attrs["description"] || attrs[:description] || controller.description),
        enabled: truthy(attrs["enabled"] || attrs[:enabled] || controller.enabled),
        updated_at: now
    }

    errors =
      %{}
      |> required(:name, controller.name)
      |> required(:phone_id, controller.phone_id)
      |> unique(controller, action)

    if map_size(errors) == 0,
      do:
        (
          Store.insert(controller)
          {:ok, controller}
        ),
      else: {:error, errors}
  end

  defp required(errors, field, value),
    do: if(value == "", do: Map.put(errors, field, "can't be blank"), else: errors)

  defp unique(errors, c, action) do
    case Store.get_by_phone_id(c.phone_id) do
      {:ok, existing} when action == :create or existing.id != c.id ->
        Map.put(errors, :phone_id, "has already been taken")

      _ ->
        errors
    end
  end

  defp trim(value), do: value |> to_string() |> String.trim()

  defp blank_nil(nil), do: nil

  defp blank_nil(value) do
    case trim(value) do
      "" -> nil
      result -> result
    end
  end

  defp truthy(value) when value in [false, "false", "0", 0], do: false

  defp truthy(_), do: true

  defp normalize_phone_id(value), do: trim(value)

  defp id, do: Base.encode32(:crypto.strong_rand_bytes(10), padding: false) |> String.downcase()
end

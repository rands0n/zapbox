defmodule ZapboxWeb.ControllerApiController do
  use ZapboxWeb, :controller
  alias Zapbox.Controllers

  def index(conn, _),
    do: json(conn, %{data: Enum.map(Controllers.list_controllers(), &serialize/1)})

  def create(conn, params) do
    case Controllers.create_controller(params) do
      {:ok, c} -> conn |> put_status(:created) |> json(%{data: serialize(c)})
      {:error, e} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: e})
    end
  end

  def show(conn, %{"id" => id}) do
    case Controllers.get_controller(id) do
      {:ok, c} -> json(conn, %{data: serialize(c)})
      :error -> send_resp(conn, 404, "")
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, c} <- Controllers.get_controller(id),
         {:ok, c} <- Controllers.update_controller(c, params) do
      json(conn, %{data: serialize(c)})
    else
      :error -> send_resp(conn, 404, "")
      {:error, e} -> conn |> put_status(:unprocessable_entity) |> json(%{errors: e})
    end
  end

  def delete(conn, %{"id" => id}) do
    case Controllers.get_controller(id) do
      {:ok, _} ->
        Controllers.delete_controller(id)
        send_resp(conn, 204, "")

      :error ->
        send_resp(conn, 404, "")
    end
  end

  defp serialize(c),
    do: Map.take(c, [:id, :name, :phone_id, :description, :enabled, :inserted_at, :updated_at])
end

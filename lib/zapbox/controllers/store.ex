defmodule Zapbox.Controllers.Store do
  @moduledoc false
  use GenServer
  @table :zapbox_controllers
  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  def init(:ok) do
    case :mnesia.start() do
      :ok -> :ok
      {:error, {:already_started, :mnesia}} -> :ok
    end

    case :mnesia.create_table(@table,
           attributes: [:id, :controller],
           disc_copies: [node()],
           type: :set
         ) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, @table}} -> :ok
    end

    :ok = :mnesia.wait_for_tables([@table], 5_000)
    {:ok, %{}}
  end

  def list,
    do:
      :mnesia.dirty_match_object({@table, :_, :_})
      |> Enum.map(fn {@table, _, c} -> c end)
      |> Enum.sort_by(&String.downcase(&1.name))

  def get(id) do
    case :mnesia.dirty_read(@table, id) do
      [{@table, ^id, c}] -> {:ok, c}
      [] -> :error
    end
  end

  def get_by_phone_id(phone_id) do
    case Enum.find(list(), &(&1.phone_id == phone_id)) do
      nil -> :error
      c -> {:ok, c}
    end
  end

  def insert(controller), do: :mnesia.dirty_write({@table, controller.id, controller})
  def delete(id), do: :mnesia.dirty_delete(@table, id)
end

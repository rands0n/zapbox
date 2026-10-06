defmodule Zapbox.Messages.Store do
  @moduledoc false
  use GenServer

  alias Zapbox.Messages.Message

  @table :zapbox_messages

  def start_link(_opts), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  @impl true
  def init(:ok) do
    ensure_node()
    data_dir = Application.get_env(:zapbox, :data_dir, Path.expand("data"))
    File.mkdir_p!(data_dir)
    Application.put_env(:mnesia, :dir, String.to_charlist(data_dir))

    case :mnesia.create_schema([node()]) do
      :ok -> :ok
      {:error, {_, {:already_exists, _}}} -> :ok
      {:error, {:already_exists, _}} -> :ok
      {:error, _reason} -> :ok
    end

    case :mnesia.start() do
      :ok -> :ok
      {:error, {:already_started, :mnesia}} -> :ok
    end

    case :mnesia.create_table(@table,
           attributes: [:id, :message],
           disc_copies: [node()],
           type: :set
         ) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, @table}} -> :ok
    end

    :ok = :mnesia.wait_for_tables([@table], 5_000)
    {:ok, %{}}
  end

  def insert(%Message{} = message) do
    :ok = :mnesia.dirty_write({@table, message.id, message})
    prune()
    :ok
  end

  def list do
    @table
    |> :mnesia.dirty_match_object({@table, :_, :_})
    |> Enum.map(fn {@table, _id, message} -> message end)
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
  end

  def get(id) do
    case :mnesia.dirty_read(@table, id) do
      [{@table, ^id, message}] -> {:ok, message}
      [] -> :error
    end
  end

  def delete(id), do: :mnesia.dirty_delete(@table, id)
  def clear, do: :mnesia.clear_table(@table)

  defp prune do
    max = Application.get_env(:zapbox, :max_messages, 500)

    list()
    |> Enum.drop(max)
    |> Enum.each(&delete(&1.id))
  end

  defp ensure_node do
    if node() == :nonode@nohost do
      System.cmd("epmd", ["-daemon"])
      name = String.to_atom("zapbox_#{System.unique_integer([:positive])}")
      {:ok, _} = :net_kernel.start([name, :shortnames])
    end
  end
end

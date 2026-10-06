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

    with :ok <- create_table(),
         :ok <- wait_for_table() do
      {:ok, %{}}
    else
      {:error, reason} -> {:stop, reason}
    end
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
      {:ok, _} = :net_kernel.start([:zapbox, :shortnames])
    end
  end

  defp create_table do
    case :mnesia.create_table(@table,
           attributes: [:id, :message],
           disc_copies: [node()],
           type: :set
         ) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, @table}} -> :ok
      {:aborted, reason} -> {:error, {:create_table_failed, @table, reason}}
    end
  end

  defp wait_for_table do
    case :mnesia.wait_for_tables([@table], 5_000) do
      :ok -> :ok
      {:timeout, [@table]} -> recover_legacy_table()
      {:timeout, tables} -> {:error, {:tables_unavailable, tables}}
    end
  end

  # Versions before 0.1.0 named every local node uniquely. Rejoin the sole
  # persisted table owner so existing volumes remain readable after upgrading.
  defp recover_legacy_table do
    case :mnesia.table_info(@table, :disc_copies) do
      [legacy_node] -> restart_as_legacy_node(legacy_node)
      nodes -> {:error, {:table_unavailable, @table, nodes}}
    end
  end

  defp restart_as_legacy_node(legacy_node) do
    _ = :mnesia.stop()
    _ = :net_kernel.stop()

    [name, host] = legacy_node |> Atom.to_string() |> String.split("@", parts: 2)
    naming = if String.contains?(host, "."), do: :longnames, else: :shortnames

    case :net_kernel.start([String.to_atom(name), naming]) do
      {:ok, _pid} ->
        with :ok <- start_mnesia(),
             :ok <- wait_for_legacy_table() do
          :ok
        end

      {:error, reason} ->
        {:error, {:legacy_node_start_failed, legacy_node, reason}}
    end
  end

  defp start_mnesia do
    case :mnesia.start() do
      :ok -> :ok
      {:error, {:already_started, :mnesia}} -> :ok
      {:error, reason} -> {:error, {:mnesia_start_failed, reason}}
    end
  end

  defp wait_for_legacy_table do
    case :mnesia.wait_for_tables([@table], 5_000) do
      :ok -> :ok
      {:timeout, tables} -> {:error, {:tables_unavailable, tables}}
    end
  end
end

defmodule Zapbox.Messages.StoreTest do
  use ExUnit.Case, async: true

  test "recovers a table persisted by a legacy randomly named node" do
    data_dir =
      Path.join(System.tmp_dir!(), "zapbox-store-test-#{System.unique_integer([:positive])}")

    on_exit(fn -> File.rm_rf!(data_dir) end)

    assert {_, 0} =
             System.cmd(
               "mix",
               ["run", "--no-start", "--no-compile", "-e", recovery_script(data_dir)],
               env: [{"MIX_ENV", "test"}],
               stderr_to_stdout: true
             )
  end

  defp recovery_script(data_dir) do
    """
    System.cmd("epmd", ["-daemon"])
    legacy_name = String.to_atom("zapbox_legacy_#{System.unique_integer([:positive])}")
    {:ok, _pid} = :net_kernel.start([legacy_name, :shortnames])
    Application.put_env(:zapbox, :data_dir, #{inspect(data_dir)})
    Application.put_env(:mnesia, :dir, String.to_charlist(#{inspect(data_dir)}))
    :ok = :mnesia.create_schema([node()])
    :ok = :mnesia.start()
    {:atomic, :ok} = :mnesia.create_table(:zapbox_messages, attributes: [:id, :message], disc_copies: [node()], type: :set)
    :ok = :mnesia.wait_for_tables([:zapbox_messages], 1_000)
    legacy_node = node()
    _ = :mnesia.stop()
    _ = :net_kernel.stop()
    Application.put_env(:zapbox, :mnesia_node_name, String.to_atom("zapbox_recovery_#{System.unique_integer([:positive])}"))
    {:ok, store} = Zapbox.Messages.Store.start_link([])
    true = node() == legacy_node
    :ok = :mnesia.wait_for_tables([:zapbox_messages], 1_000)
    :ok = GenServer.stop(store)
    """
  end
end

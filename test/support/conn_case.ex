defmodule ZapboxWeb.ConnCase do
  @moduledoc """
  Shared connection setup for Zapbox HTTP and LiveView tests.

  Mnesia-backed tests are responsible for isolating their own stored data.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint ZapboxWeb.Endpoint

      use ZapboxWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ZapboxWeb.ConnCase
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end

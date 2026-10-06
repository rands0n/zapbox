defmodule ZapboxWeb.PageControllerTest do
  use ZapboxWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Local WhatsApp inbox"
  end
end

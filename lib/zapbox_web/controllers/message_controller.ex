defmodule ZapboxWeb.MessageController do
  use ZapboxWeb, :controller
  alias Zapbox.Messages

  def create(conn, %{"version" => version, "phone_id" => phone_id} = body) do
    {_message, response} = Messages.capture(version, phone_id, body, conn.req_headers)
    json(conn, response)
  end
end

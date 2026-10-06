defmodule Zapbox.Messages.Message do
  @moduledoc "The persisted representation of a captured Cloud API request."

  @enforce_keys [
    :id,
    :wa_message_id,
    :api_version,
    :phone_id,
    :request_body,
    :request_headers,
    :response_body,
    :response_status,
    :inserted_at
  ]
  defstruct [
    :id,
    :wa_message_id,
    :api_version,
    :phone_id,
    :to,
    :recipient_type,
    :message_type,
    :template_name,
    :language,
    :request_body,
    :request_headers,
    :response_body,
    :response_status,
    :inserted_at
  ]
end

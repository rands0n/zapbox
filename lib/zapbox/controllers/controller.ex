defmodule Zapbox.Controllers.Controller do
  @moduledoc false
  @enforce_keys [:id, :name, :phone_id, :enabled, :inserted_at, :updated_at]
  defstruct [:id, :name, :phone_id, :description, :enabled, :inserted_at, :updated_at]
end

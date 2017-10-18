defmodule TestController do
  @moduledoc """
  Module that uses the Cassette.Controller macro for testing
  """

  use Cassette.Controller, on_forbidden: fn(conn) ->
    conn |> send_resp(403, "you cannot") |> halt
  end
end

defmodule TestController do
  use Cassette.Controller, on_forbidden: fn(conn) ->
    conn |> send_resp(403, "you cannot") |> halt
  end
end

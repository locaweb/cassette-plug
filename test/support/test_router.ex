defmodule TestRouter do
  @moduledoc """
  Router used in tests
  """

  use Plug.Router

  require Cassette.Plug

  import Cassette.Plug, only: [require_role: 1]

  require_role(role: "testing")

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "olar")
  end
end

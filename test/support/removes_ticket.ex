defmodule RemovesTicket do
  @moduledoc """
  Macro module with a test asserting that a given url has its ticket param
  removed
  """

  alias Cassette.Plug.DefaultHandler
  alias Plug.Conn

  defmacro test_removes_ticket(source, expected) do
    quote do
      test "url/2 removes the ticket from #{unquote(source)}" do
        conn = %{conn(:get, unquote(source)) | host: "example.org"} |> Conn.fetch_query_params()

        assert DefaultHandler.url(conn, []) == "http://example.org#{unquote(expected)}"
      end
    end
  end
end

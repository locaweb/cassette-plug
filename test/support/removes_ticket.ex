defmodule RemovesTicket do
  @moduledoc """
  Macro module with a test asserting that a given url has its ticket param
  removed
  """

  defmacro test_removes_ticket(source, expected) do
    quote do
      test "url/2 removes the ticket from #{unquote(source)}" do
        conn =
          %{conn(:get, unquote(source)) | host: "example.org"} |> Plug.Conn.fetch_query_params()

        assert Cassette.Plug.DefaultHandler.url(conn, []) ==
                 "http://example.org#{unquote(expected)}"
      end
    end
  end
end

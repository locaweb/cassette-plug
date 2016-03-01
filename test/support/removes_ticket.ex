defmodule RemovesTicket do
  defmacro test_removes_ticket(source, expected) do
    quote do
      test "url/2 removes the ticket from #{unquote(source)}" do
        conn = %{conn(:get, unquote(source)) | host: "example.org"} |> Plug.Conn.fetch_query_params
        assert Cassette.Plug.url(conn, []) == "http://example.org:80#{unquote(expected)}"
      end
    end
  end
end

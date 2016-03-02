defmodule Cassette.Plug.DefaultHandler do
  import Plug.Conn

  def service(conn, options) do
    url(conn, options)
  end

  def unauthenticated(conn, options) do
    cassette = Keyword.get(options, :cassette, Cassette)
    location = "#{cassette.config.base_url}/login?service=#{URI.encode(url(conn, options))}"
    conn |> put_resp_header("location", location) |> send_resp(307, "") |> halt
  end

  def invalid_authentication(conn, _options) do
    conn |> resp(403, "Forbidden") |> halt
  end

  @spec url(Plug.Conn.t, term) :: String.t
  @doc """
  Computes the service from the URL requested in the `conn` argument.
  It will remove the `ticket` from the query string paramaters since the ticket has not been generated with it.
  """
  def url(conn, _options) do
    query_string =
      conn.query_params
      |> Enum.reject(fn({k, _}) -> k == "ticket" end)
      |> URI.encode_query

    ["#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}", query_string]
    |> Enum.reject(fn(v) -> is_nil(v) || v == "" end)
    |> Enum.join("?")
  end
end

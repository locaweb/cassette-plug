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
    ["#{conn.scheme}://#{conn.host}#{url_port_string(conn)}#{conn.request_path}", query_string(conn)]
    |> Enum.reject(fn(v) -> is_nil(v) || v == "" end)
    |> Enum.join("?")
  end

  defp query_string(conn = %Plug.Conn{query_params: %Plug.Conn.Unfetched{aspect: :query_params}}) do
    query_string(conn |> Plug.Conn.fetch_query_params)
  end

  defp query_string(conn) do
    conn.query_params
    |> Enum.reject(fn({k, _}) -> k == "ticket" end)
    |> URI.encode_query
  end

  defp url_port_string(%Plug.Conn{port: 80, scheme: :http}), do: ""
  defp url_port_string(%Plug.Conn{port: 443, scheme: :https}), do: ""
  defp url_port_string(conn = %Plug.Conn{}), do: ":#{conn.port}"
end

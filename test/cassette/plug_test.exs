defmodule Cassette.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import RemovesTicket

  setup tags do
    if tags[:session] do
      session_opts = Plug.Session.init(store: :cookie, key: "_palantir_key",
                                   encryption_salt: "As34Atb", signing_salt: "eTcLslAt")

      conn = conn(:get, tags[:path] || "/", tags[:body] || %{})
      |> Plug.Session.call(session_opts)
      |> Plug.Conn.fetch_session()
      |> Plug.Conn.fetch_query_params()

      {:ok, conn: conn}
    else
      :ok
    end
  end

  test "url/2 builds the current request url" do
    conn = %{conn(:get, "/foo?bar=42") | host: "example.org"} |> Plug.Conn.fetch_query_params

    assert Cassette.Plug.url(conn, []) == "http://example.org:80/foo?bar=42"
  end

  test_removes_ticket("/", "/")
  test_removes_ticket("/?ticket=x", "/")
  test_removes_ticket("/?master=1&ticket=x", "/?master=1")
  test_removes_ticket("/foo", "/foo")
  test_removes_ticket("/foo?bar=42", "/foo?bar=42")
  test_removes_ticket("/foo?bar=42&ticket=master", "/foo?bar=42")
  test_removes_ticket("/foo?ticket=master", "/foo")
  test_removes_ticket("/foo?ticket=master&bar=42", "/foo?bar=42")

  test "service/2 returns the configured service from the default Cassette client if not provided" do
    conn = %Plug.Conn{}

    assert Cassette.config.service == Cassette.Plug.service(conn, [])
  end

  test "service/2 returns the configued service from the provided Cassette client" do
    conn = %Plug.Conn{}

    assert CassetteMock.config.service == Cassette.Plug.service(conn, [cassette: CassetteMock])
  end

  @tag session: true
  test "call/2 with no user in session and no ticket redirects to auth", %{conn: conn} do
    assert %Plug.Conn{status: 307, halted: true, resp_headers: headers} = Cassette.Plug.call(conn, [cassette: CassetteMock])

    assert Enum.member?(headers, {"location", "#{CassetteMock.config.base_url}/login?service=http://www.example.com:80/"})
  end

  @tag session: true
  test "call/2 a user in session does not halt the connection", %{conn: conn} do
    conn = conn |> Plug.Conn.put_session("cas_user", CassetteMock.valid_user)

    assert %Plug.Conn{halted: false} = Cassette.Plug.call(conn, [cassette: CassetteMock])
  end

  @tag session: true, path: "/?ticket=#{CassetteMock.valid_ticket}"
  test "call/2 with no user and valid ticket does not halt the connection", %{conn: conn} do
    assert %Plug.Conn{halted: false} = Cassette.Plug.call(conn, [cassette: CassetteMock])
  end

  @tag session: true, path: "/?ticket=#{CassetteMock.valid_ticket}"
  test "call/2 with no user and valid ticket sets the user in the session", %{conn: conn} do
    assert CassetteMock.valid_user ==
      conn
      |> Cassette.Plug.call([cassette: CassetteMock])
      |> Plug.Conn.get_session("cas_user")
  end

  @tag session: true, path: "/?ticket=#{CassetteMock.invalid_ticket}"
  test "call/2 with no user and invalid ticket halts the connection with forbidden", %{conn: conn} do
    assert %Plug.Conn{halted: true, status: 403} = Cassette.Plug.call(conn, [cassette: CassetteMock])
  end
end

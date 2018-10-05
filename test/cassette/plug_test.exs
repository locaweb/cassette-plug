defmodule Cassette.PlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import ExUnit.CaptureLog

  alias Plug.Conn

  alias Cassette.Plug

  setup tags do
    if tags[:session] do
      conn =
        :get
        |> conn(tags[:path] || "/", tags[:body] || %{})
        |> init_test_session([])
        |> Conn.fetch_query_params()

      {:ok, conn: conn}
    else
      :ok
    end
  end

  test "init/1 returns a keyword" do
    assert [] = Plug.init([])
  end

  @tag session: true
  test "call/2 with no user in session and no ticket redirects to auth", %{conn: conn} do
    assert %Conn{status: 307, halted: true, resp_headers: headers} =
             Plug.call(conn, cassette: CassetteMock)

    assert Enum.member?(
             headers,
             {"location",
              "#{CassetteMock.config().base_url}/login?service=http://www.example.com/"}
           )
  end

  @tag session: true
  test "call/2 a user in session does not halt the connection", %{conn: conn} do
    conn = Conn.put_session(conn, "cas_user", CassetteMock.valid_user())

    assert %Conn{halted: false} = Plug.call(conn, cassette: CassetteMock)
  end

  @tag session: true, path: "/?ticket=#{CassetteMock.valid_ticket()}"
  test "call/2 with no user and valid ticket does not halt the connection", %{conn: conn} do
    assert %Conn{halted: false} = Plug.call(conn, cassette: CassetteMock)
  end

  @tag session: true, path: "/?ticket=#{CassetteMock.valid_ticket()}"
  test "call/2 with no user and valid ticket sets the user in the session", %{conn: conn} do
    assert CassetteMock.valid_user() ==
             conn
             |> Plug.call(cassette: CassetteMock)
             |> Conn.get_session("cas_user")
  end

  @tag session: true, path: "/?ticket=#{CassetteMock.invalid_ticket()}"
  test "call/2 with no user and invalid ticket halts the connection with forbidden", %{conn: conn} do
    capture_log(fn ->
      assert %Conn{halted: true, status: 403} = Plug.call(conn, cassette: CassetteMock)
    end)
  end

  @tag session: true, path: "/?ticket=#{CassetteMock.invalid_ticket()}"
  test "call/2 logs the authentication failure", %{conn: conn} do
    log = capture_log(fn -> Plug.call(conn, cassette: CassetteMock) end)

    assert log =~ "Validation of \"#{CassetteMock.invalid_ticket()}\" failed"
  end
end

defmodule Cassette.ControllerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import TestController

  setup tags do
    session_opts = Plug.Session.init(store: :cookie, key: "_session_key",
     signing_salt: "abcd1234", encryption_salt: "efgh5678")

    user = if tags[:with_user] do
      CassetteMock.valid_user
    else
      nil
    end

    conn = conn(:get, tags[:path] || "/", tags[:body] || %{})
    |> Map.put(:secret_key_base, Application.get_env(:cassette_plug, :secret_key_base))
    |> Plug.Session.call(session_opts)
    |> Plug.Conn.fetch_session()
    |> Plug.Conn.fetch_query_params()
    |> Plug.Conn.put_session("cas_user", user)

    {:ok, conn: conn}
  end

  test "has_role?/2 returns false when session has no user (when role is a string)", %{conn: conn} do
    refute conn |> has_role?("ADMIN")
  end

  test "has_role?/2 returns false when session has no user (when role is a list)", %{conn: conn} do
    refute conn |> has_role?(["EXAMPLE_ADMIN", "EXAMPLE_MANAGER"])
  end

  test "has_role?/2 returns false when session has no user (when role is a function)", %{conn: conn} do
    refute conn |> has_role?(fn(_conn) -> "EXAMPLE_ADMIN" end)
  end

  @tag with_user: true
  test "has_role?/2 returns true when the user has any of the roles listed", %{conn: conn} do
    assert conn |> has_role?(["ADMIN", "SOME_WEIRD_ROLE"])
  end

  @tag with_user: true
  test "has_role?/2 returns false when the user does not have any of the roles listed", %{conn: conn} do
    refute conn |> has_role?(["SOME_WEIRD_ROLE", "ANOTHER_WEIRD_ROLE"])
  end

  @tag with_user: true
  test "has_role?/2 returns true when the user has the role", %{conn: conn} do
    assert conn |> has_role?("ADMIN")
  end

  @tag with_user: true
  test "has_role?/2 returns false when the user does not have the role", %{conn: conn} do
    refute conn |> has_role?("SOME_WEIRD_ROLE")
  end

  @tag with_user: true
  test "has_role?/2 returns true when the user has the role (when role is a function)", %{conn: conn} do
    assert conn |> has_role?(fn(_conn) -> "ADMIN" end)
  end

  @tag with_user: true
  test "has_role?/2 returns false when the user does not have the role (when role is a function)", %{conn: conn} do
    refute conn |> has_role?(fn(_conn) -> "SOME_WEIRD_ROLE" end)
  end

  @tag with_user: false
  test "require_role!/2 halts the connection when there is no user in session", %{conn: conn} do
    assert %Plug.Conn{halted: true, status: 403} = conn |> require_role!("ADMIN")
  end

  @tag with_user: true
  test "require_role!/2 halts the connection when user does not have the role", %{conn: conn} do
    assert %Plug.Conn{halted: true, status: 403} = conn |> require_role!("SOME_WEIRD_ROLE")
  end

  @tag with_user: true
  test "require_role!/2 calls the `on_forbidden` callback", %{conn: conn} do
    assert %Plug.Conn{status: 403, resp_body: "you cannot"} = conn |> require_role!("SOME_WEIRD_ROLE")
  end

  @tag with_user: true
  test "require_role!/2 does not halt the connection when user has the role", %{conn: conn} do
    assert %Plug.Conn{halted: false} = conn |> require_role!("ADMIN")
  end

  test "has_raw_role?/2 returns false when session has no user (when role is a string)", %{conn: conn} do
    refute conn |> has_raw_role?("ACME_ADMIN")
  end

  test "has_raw_role?/2 returns false when session has no user (when role is a list)", %{conn: conn} do
    refute conn |> has_raw_role?(["EXAMPLE_ADMIN", "EXAMPLE_MANAGER"])
  end

  test "has_raw_role?/2 returns false when session has no user (when role is a function)", %{conn: conn} do
    refute conn |> has_raw_role?(fn(_conn) -> "EXAMPLE_ADMIN" end)
  end

  @tag with_user: true
  test "has_raw_role?/2 returns true when the user has any of the roles listed", %{conn: conn} do
    assert conn |> has_raw_role?(["ACME_ADMIN", "SOME_WEIRD_ROLE"])
  end

  @tag with_user: true
  test "has_raw_role?/2 returns false when the user does not have any of the roles listed", %{conn: conn} do
    refute conn |> has_raw_role?(["SOME_WEIRD_ROLE", "ANOTHER_WEIRD_ROLE"])
  end

  @tag with_user: true
  test "has_raw_role?/2 returns true when the user has the role", %{conn: conn} do
    assert conn |> has_raw_role?("ACME_ADMIN")
  end

  @tag with_user: true
  test "has_raw_role?/2 returns false when the user does not have the role", %{conn: conn} do
    refute conn |> has_raw_role?("SOME_WEIRD_ROLE")
  end

  @tag with_user: true
  test "has_raw_role?/2 returns true when the user has the role (when role is a function)", %{conn: conn} do
    assert conn |> has_raw_role?(fn(_conn) -> "ACME_ADMIN" end)
  end

  @tag with_user: true
  test "has_raw_role?/2 returns false when the user does not have the role (when role is a function)", %{conn: conn} do
    refute conn |> has_raw_role?(fn(_conn) -> "SOME_WEIRD_ROLE" end)
  end

  @tag with_user: false
  test "require_raw_role!/2 halts the connection when there is no user in session", %{conn: conn} do
    assert %Plug.Conn{halted: true, status: 403} = conn |> require_raw_role!("ACME_ADMIN")
  end

  @tag with_user: true
  test "require_raw_role!/2 halts the connection when user does not have the role", %{conn: conn} do
    assert %Plug.Conn{halted: true, status: 403} = conn |> require_raw_role!("SOME_WEIRD_ROLE")
  end

  @tag with_user: true
  test "require_raw_role!/2 does not halt the connection when user has the role", %{conn: conn} do
    assert %Plug.Conn{halted: false} = conn |> require_raw_role!("ACME_ADMIN")
  end

  @tag with_user: true
  test "require_raw_role!/2 calls the `on_forbidden` callback", %{conn: conn} do
    assert %Plug.Conn{status: 403, resp_body: "you cannot"} = conn |> require_raw_role!("SOME_WEIRD_ROLE")
  end
end

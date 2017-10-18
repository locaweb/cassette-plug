defmodule Cassette.ControllerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import TestController

  setup tags do
    user = if tags[:with_user] do
      CassetteMock.valid_user
    else
      nil
    end

    conn =
      :get
      |> conn(tags[:path] || "/", tags[:body] || %{})
      |> init_test_session(cas_user: user)

    {:ok, conn: conn}
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

defmodule Cassette.Plug.RequireRolePlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Plug.Conn

  import Cassette.Plug.RequireRolePlug

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

  describe "init/1" do
    test "it fails if no role is provided" do
      assert_raise KeyError, fn ->
        init([])
      end
    end

    test "it returns the given options" do
      assert [role: "ADMIN"] = init(role: "ADMIN")
    end
  end

  describe "call/2" do
    test "it sends a 403 when role is not present", %{conn: conn} do
      assert 403 == TestRouter.call(conn, []).status
    end

    test "it does not alter the conn when role is present", %{conn: conn} do
      alias Cassette.User

      assert %Conn{status: 200} =
        conn
        |> init_test_session(cas_user: User.new("acme", ["ACME_TESTING"]))
        |> TestRouter.call([])
    end
  end

  describe "has_role?/3" do
    test "has_role?/3 returns false when session has no user (when role is a string)", %{conn: conn} do
      refute has_role?(conn, "ADMIN", [])
    end

    test "has_role?/3 returns false when session has no user (when role is a list)", %{conn: conn} do
      refute has_role?(conn, ["EXAMPLE_ADMIN", "EXAMPLE_MANAGER"], [])
    end

    test "has_role?/3 returns false when session has no user (when role is a function)", %{conn: conn} do
      refute has_role?(conn, fn(_conn) -> "EXAMPLE_ADMIN" end, [])
    end

    @tag with_user: true
    test "has_role?/3 returns true when the user has any of the roles listed", %{conn: conn} do
      assert has_role?(conn, ["ADMIN", "SOME_WEIRD_ROLE"], [])
    end

    @tag with_user: true
    test "has_role?/3 returns false when the user does not have any of the roles listed", %{conn: conn} do
      refute has_role?(conn, ["SOME_WEIRD_ROLE", "ANOTHER_WEIRD_ROLE"], [])
    end

    @tag with_user: true
    test "has_role?/3 returns true when the user has the role", %{conn: conn} do
      assert has_role?(conn, "ADMIN", [])
    end

    @tag with_user: true
    test "has_role?/3 returns false when the user does not have the role", %{conn: conn} do
      refute has_role?(conn, "SOME_WEIRD_ROLE", [])
    end

    @tag with_user: true
    test "has_role?/3 returns true when the user has the role (when role is a function)", %{conn: conn} do
      assert has_role?(conn, fn(_conn) -> "ADMIN" end, [])
    end

    @tag with_user: true
    test "has_role?/3 returns false when the user does not have the role (when role is a function)", %{conn: conn} do
      refute has_role?(conn, fn(_conn) -> "SOME_WEIRD_ROLE" end, [])
    end
  end

  describe "has_raw_role?/2" do
    test "has_raw_role?/2 returns false when session has no user (when role is a string)", %{conn: conn} do
      refute has_raw_role?(conn, "ACME_ADMIN")
    end

    test "has_raw_role?/2 returns false when session has no user (when role is a list)", %{conn: conn} do
      refute has_raw_role?(conn, ["EXAMPLE_ADMIN", "EXAMPLE_MANAGER"])
    end

    test "has_raw_role?/2 returns false when session has no user (when role is a function)", %{conn: conn} do
      refute has_raw_role?(conn, fn(_conn) -> "EXAMPLE_ADMIN" end)
    end

    @tag with_user: true
    test "has_raw_role?/2 returns true when the user has any of the roles listed", %{conn: conn} do
      assert has_raw_role?(conn, ["ACME_ADMIN", "SOME_WEIRD_ROLE"])
    end

    @tag with_user: true
    test "has_raw_role?/2 returns false when the user does not have any of the roles listed", %{conn: conn} do
      refute has_raw_role?(conn, ["SOME_WEIRD_ROLE", "ANOTHER_WEIRD_ROLE"])
    end

    @tag with_user: true
    test "has_raw_role?/2 returns true when the user has the role", %{conn: conn} do
      assert has_raw_role?(conn, "ACME_ADMIN")
    end

    @tag with_user: true
    test "has_raw_role?/2 returns false when the user does not have the role", %{conn: conn} do
      refute has_raw_role?(conn, "SOME_WEIRD_ROLE")
    end

    @tag with_user: true
    test "has_raw_role?/2 returns true when the user has the role (when role is a function)", %{conn: conn} do
      assert has_raw_role?(conn, fn(_conn) -> "ACME_ADMIN" end)
    end

    @tag with_user: true
    test "has_raw_role?/2 returns false when the user does not have the role (when role is a function)", %{conn: conn} do
      refute has_raw_role?(conn, fn(_conn) -> "SOME_WEIRD_ROLE" end)
    end
  end
end

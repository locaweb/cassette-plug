defmodule Cassette.Controller do
  @moduledoc """
  A helper module to quickly validate roles and get the current user
  """

  import Plug.Conn

  @spec current_user(Plug.Conn.t) :: Cassette.User.t | nil
  @doc """
  Fetches the current user from the session.

  Returns `nil` if has no user
  """
  def current_user(conn) do
    conn |> fetch_session |> get_session("cas_user")
  end

  @doc """
  Tests if the user has roles.

  When roles is a list, tests if `current_user` has *any* of the roles.

  When roles ia function, it will receive the `Plug.Conn.t` and must return role to validate.

  Returns `false` if there is no user in the session.
  """
  @spec has_role?(Plug.Conn.t, [String.t]) :: boolean
  def has_role?(conn, roles) when is_list(roles) do
    user = current_user(conn)
    Enum.any?(roles, &Cassette.User.has_role?(user, &1))
  end

  @spec has_role?(Plug.Conn.t, ((Plug.Conn.t) -> String.t)) :: boolean
  def has_role?(conn, role_fn) when is_function(role_fn, 1) do
    has_role?(conn, role_fn.(conn))
  end

  @spec has_role?(Plug.Conn.t, String.t) :: boolean
  def has_role?(conn, role) do
    has_role?(conn, [role])
  end

  @doc """
  Tests if the user has (raw) roles.

  Arguments follow the same logic as has_role?/2 but they are forwarded to `Cassette.User.has_raw_role?/2`
  """
  @spec has_raw_role?(Plug.Conn.t, [String.t]) :: boolean
  def has_raw_role?(conn, roles) when is_list(roles) do
    user = current_user(conn)
    Enum.any?(roles, &Cassette.User.has_raw_role?(user, &1))
  end

  @spec has_raw_role?(Plug.Conn.t, ((Plug.Conn.t) -> String.t)) :: boolean
  def has_raw_role?(conn, role_fn) when is_function(role_fn, 1) do
    has_raw_role?(conn, role_fn.(conn))
  end

  @spec has_raw_role?(Plug.Conn.t, String.t) :: boolean
  def has_raw_role?(conn, role) do
    has_raw_role?(conn, [role])
  end

  @spec require_role!(Plug.Conn.t, String.t | [String.t] | ((Plug.Conn.t) -> String.t)) :: Plug.Conn.t
  @doc """
  Tests if the user has the role. Where role can be any of the terms accepted by any implementation of `has_role?/2`.

  This will halt the connection and set the status to forbidden if authorization fails.
  """
  def require_role!(conn, roles) do
    if has_role?(conn, roles) do
      conn
    else
      conn |> resp(403, ~s({"error":"forbidden"})) |> halt
    end
  end

  @spec require_raw_role!(Plug.Conn.t, String.t | [String.t] | ((Plug.Conn.t) -> String.t)) :: Plug.Conn.t
  @doc """
  Tests if the user has the (raw) role. Where role can be any of the terms accepted by any implementation of `has_raw_role?/2`.

  This will halt the connection and set the status to forbidden if authorization fails.
  """
  def require_raw_role!(conn, roles) do
    if has_raw_role?(conn, roles) do
      conn
    else
      conn |> resp(403, ~s({"error":"forbidden"})) |> halt
    end
  end
end

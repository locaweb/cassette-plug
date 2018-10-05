defmodule Cassette.Plug.RequireRolePlug do
  @moduledoc """
  Plug to check presence of user roles
  """

  @behaviour Plug

  import Plug.Conn

  alias Cassette.User
  alias Plug.Conn

  @type role_param :: String.t() | [String.t()] | (Conn.t() -> String.t())

  def init(opts) do
    _role = Keyword.fetch!(opts, :role)

    opts
  end

  @doc """
  Fetches the current user from the session.

  Returns `nil` if has no user
  """
  @spec current_user(Conn.t()) :: User.t() | nil
  def current_user(conn) do
    conn
    |> fetch_session
    |> get_session("cas_user")
  end

  defp __config__(opts) do
    apply(opts[:cassette] || Cassette, :config, [])
  end

  defdelegate has_role?(conn, roles, opts), to: __MODULE__, as: :role?

  @doc """
  Tests if the user has roles.

  When roles is a list, tests if `current_user` has *any* of the roles.

  When roles ia function, it will receive the `Plug.Conn.t` and must return role to validate.

  Returns `false` if there is no user in the session.
  """
  @spec role?(Conn.t(), role_param, Keyword.t()) :: boolean
  def role?(conn, roles, opts) when is_list(roles) do
    user = current_user(conn)
    Enum.any?(roles, &User.has_role?(user, __config__(opts), &1))
  end

  def role?(conn, role_fn, opts) when is_function(role_fn, 1) do
    role?(conn, role_fn.(conn), opts)
  end

  def role?(conn, role, opts) do
    role?(conn, [role], opts)
  end

  defdelegate has_raw_role?(conn, roles), to: __MODULE__, as: :raw_role?

  @doc """
  Tests if the user has (raw) roles.

  Arguments follow the same logic as role?/2 but they are forwarded to `Cassette.User.has_raw_role?/2`
  """
  @spec raw_role?(Conn.t(), role_param) :: boolean
  def raw_role?(conn, roles) when is_list(roles) do
    user = current_user(conn)
    Enum.any?(roles, &User.has_raw_role?(user, &1))
  end

  def raw_role?(conn, role_fn) when is_function(role_fn, 1) do
    raw_role?(conn, role_fn.(conn))
  end

  def raw_role?(conn, role) do
    raw_role?(conn, [role])
  end

  def call(conn, opts) do
    role = Keyword.fetch!(opts, :role)

    if role?(conn, role, opts) do
      conn
    else
      (opts[:on_forbidden] ||
         fn c ->
           c |> resp(403, "Forbidden") |> halt
         end).(conn)
    end
  end
end

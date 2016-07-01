defmodule Cassette.Controller do
  @moduledoc """
  A helper module to quickly validate roles and get the current user

  To use in your controller, add as a plug restricting the actions:

  ```elixir

  defmodule MyApp.MyController do
    use MyApp.Web, :controller
    use Cassette.Controller

    plug :require_role!, "ADMIN" when action in [:edit, :update, :new, :create]

    def update(conn, %{"id" => id}) do
      something = Repo.get!(Something, id)
      changeset = Something.changeset(something)
      render(conn, "edit.html", something: something, changeset: changeset)
    end
  end

  ```

  You can also customize how a forbidden situation is handled:

  ```elixir

  defmodule MyApp.MyController do
    use MyApp.Web, :controller
    use Cassette.Controller, on_forbidden: fn(conn) ->
      redirect(conn, to: "/403.html")
    end

    plug :require_role!("VIEWER")

    def index(conn, _params) do
      render(conn, "index.html")
    end
  end

  ```

  You can use one of your controller functions as well:

  ```elixir

  defmodule MyApp.MyController do
    use MyApp.Web, :controller
    use Cassette.Controller, on_forbidden: &MyApp.MyController.forbidden/1

    plug :require_role!("VIEWER")

    def index(conn, _params) do
      render(conn, "index.html")
    end
  end

  ```

  Or since `require_role!/2` halts the connection you may do the following for simple actions.

  ```elixir

  defmodule MyApp.MyController do
    use MyApp.Web, :controller
    use Cassette.Controller

    def index(conn, _params) do
      conn
      |> require_role!("VIEWER")
      |> render("index.html")
    end
  end

  ```

  You can also write your own plugs using the "softer" `has_role?/2` or `has_raw_role?/2`:

  ```elixir

  defmodule MyApp.MyController do
    use MyApp.web, :controller
    use Cassette.Controller

    plug :check_authorization

    def index(conn, _params) do
      render(conn, "index.html")
    end

    def check_authorization(conn, _params) do
      if has_role?("viewer") do
        conn
      else
        conn |> render("forbidden.html") |> halt
      end
    end
  end

  ```


  """

  defmacro __using__(opts \\ []) do
    quote do
      import Plug.Conn

      defp __config__, do: (unquote(opts[:cassette]) || Cassette).config

      defp __forbidden_callback__, do: unquote(opts[:on_forbidden]) || fn(conn) ->
        conn |> resp(403, "Forbidden") |> halt
      end

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
        Enum.any?(roles, &Cassette.User.has_role?(user, __config__, &1))
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
          __forbidden_callback__.(conn)
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
          __forbidden_callback__.(conn)
        end
      end
    end
  end
end

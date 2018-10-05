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

    plug :require_role!, "VIEWER"

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

    plug :require_role! "VIEWER"

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
      if has_role?(conn, "viewer") do
        conn
      else
        conn
        |> render("forbidden.html")
        |> halt
      end
    end
  end

  ```

  """

  alias Cassette.Plug.RequireRolePlug
  alias Plug.Conn

  defmacro __using__(opts \\ []) do
    quote do
      import Conn

      import Cassette.Plug.RequireRolePlug,
        only: [current_user: 1, has_role?: 3, has_raw_role?: 2]

      defp __forbidden_callback__ do
        unquote(opts[:on_forbidden]) ||
          fn conn ->
            conn
            |> resp(403, "Forbidden")
            |> halt
          end
      end

      @doc """
      Tests if the user has the role. Where role can be any of the terms accepted by any implementation of `has_role?/2`.

      This will halt the connection and set the status to forbidden if authorization fails.
      """
      @spec require_role!(Conn.t(), RequireRolePlug.role_param()) :: Conn.t()
      def require_role!(conn, roles) do
        if has_role?(conn, roles, unquote(opts)) do
          conn
        else
          __forbidden_callback__().(conn)
        end
      end

      @doc """
      Returns if the user has the role.
      """
      @spec has_role?(Conn.t(), RequireRolePlug.role_param()) :: boolean
      def has_role?(conn, roles) do
        has_role?(conn, roles, unquote(opts))
      end

      @doc """
      Tests if the user has the (raw) role. Where role can be any of the terms accepted by any implementation of `has_raw_role?/2`.

      This will halt the connection and set the status to forbidden if authorization fails.
      """
      @spec require_raw_role!(Conn.t(), RequireRolePlug.role_param()) :: Conn.t()
      def require_raw_role!(conn, roles) do
        if has_raw_role?(conn, roles) do
          conn
        else
          __forbidden_callback__().(conn)
        end
      end
    end
  end
end

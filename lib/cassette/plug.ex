defmodule Cassette.Plug do
  @moduledoc """
  A plug to authenticate using Cassette

  When plugged, this will test the session for the presence of the user.
  When not present it will test for presence of a ticket parameter and validate it.
  If none of those are present, it will redirect the user to the cas login.

  To add to your router:

  ```
  defmodule Router do
    use Plug.Router

    plug Cassette.Plug

    plug :match
    plug :dispatch

    (...)
  end
  ```

  Just be sure that your `Plug.Session` is configured and plugged before `Cassette.Plug`

  If you are using this with phoenix, plug into one of your pipelines:

  ```
  defmodule MyApp.Router do
    use MyApp.Web, :router

    pipeline :browser do
      (...)
      plug :fetch_session
      plug Cassette.Plug
      plug :fetch_flash
      (...)
    end
  end
  ```

  Be sure that is module is plugged after the `:fetch_session` plug since this is a requirement

  ## Customizing behaviour

  The behaviour for authentication failures may be customized using your own
  `Cassette.Plug.AuthenticationHandler`.
  Please refer to the documentation on that module for more details.

  """

  @behaviour Plug

  require Logger

  alias Cassette.Plug.AuthenticationHandler
  alias Cassette.Support
  alias Cassette.User

  alias Plug.Builder
  alias Plug.Conn

  @type options :: [cassette: Support.t(), handler: AuthenticationHandler.t()]

  @spec init([]) :: []
  @doc "Initializes this plug"
  def init(options), do: options

  @doc """
  Runs this plug.

  Your custom Cassette module may be provided with the `:cassette` key. It will default to the
  `Cassette` module.
  """
  @spec call(Conn.t(), options) :: Conn.t()
  def call(conn, options) do
    cassette = Keyword.get(options, :cassette, Cassette)
    handler = Keyword.get(options, :handler, AuthenticationHandler.default())

    case handler.user_or_token(conn, options) do
      {%User{}, _} ->
        conn

      {nil, :error} ->
        handler.unauthenticated(conn, options)

      {nil, {:ok, ticket}} ->
        case cassette.validate(ticket, handler.service(conn, options)) do
          {:ok, user} ->
            handler.user_authenticated(conn, user, options)

          {:error, reason} ->
            Logger.error("Validation of #{inspect(ticket)} failed: #{inspect(reason)}")
            handler.invalid_authentication(conn, options)
        end
    end
  end

  defmacro require_role(options) do
    quote do
      Builder.plug(Cassette.Plug.RequireRolePlug, unquote(options))
    end
  end
end

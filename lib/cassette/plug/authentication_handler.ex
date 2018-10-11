defmodule Cassette.Plug.AuthenticationHandler do
  @moduledoc """
  Behaviour and macro module to define callbacks for the authentication handlers the plug uses.

  Most of this works out-of-the-box, but it might be interesting to override
  `Cassette.Plug.AuthenticationHandler.invalid_authentication/2` and present a more friendy error page

  ```elixir

  defmodule MyErrorHandler do
    use Cassette.Plug.AuthenticationHandler

    def invalid_authentication(conn, _options) do
      render(conn, "error")
    end
  end

  ```

  And while plugging in your router:

  ```elixir

  plug Cassette.Plug, handler: MyErrorHandler

  ```

  Check `Cassette.Plug.DefaultHandler` for the default behaviour.

  """

  alias Cassette.User
  alias Plug.Conn

  @type t :: module()

  @doc """
  Initializes this handler with the given options.

  They will be forwarded to the other functions.
  """
  @callback init(args :: term) :: term

  @doc """
  Called to compute the service that must be authenticated against.

  Usually this is the URL of the page the user is trying to access and may be computed using values in `conn`
  """
  @callback service(conn :: Conn.t(), options :: term) :: String.t()

  @doc """
  Called when there is no authentication in the request (i.e., no `ticket` in the query string).

  The usual implementation is to redirect to CAS.
  """
  @callback unauthenticated(conn :: Conn.t(), options :: term) :: Conn.t()

  @doc """
  Called when authentication is provided but fails (i.e., ticket is no longer valid or is invalid).

  This might be your Forbidden page.
  """
  @callback invalid_authentication(conn :: Conn.t(), options :: term) :: Conn.t()

  @doc """
  Called to extract the current authenticated user and/or the authentication token from `conn`
  """
  @callback user_or_token(conn :: Conn.t(), options :: term) ::
              {User.t() | nil, {:ok, String.t()} | :error}

  @doc """
  Called when successfully authenticated the user on `conn`
  """
  @callback user_authenticated(conn :: Conn.t(), user :: User.t(), options :: term) :: Conn.t()

  @doc """
  Returns the default implementation for this behaviour
  """
  @spec default :: Cassette.Plug.AuthenticationHandler.t()
  def default do
    Cassette.Plug.DefaultHandler
  end

  defmacro __using__(_options) do
    quote do
      @behaviour Cassette.Plug.AuthenticationHandler

      import Conn

      @spec init(args :: term) :: term
      def init(options), do: options

      @doc """
      Builds the current request url to be used as the CAS service
      """
      @spec service(conn :: Conn.t(), options :: term) :: String.t()
      def service(conn, options) do
        url(conn, options)
      end

      @doc """
      Redirects the user to the cas login page with the service computed by `service/2`
      """
      @spec unauthenticated(conn :: Conn.t(), options :: term) :: Conn.t()
      def unauthenticated(conn, options) do
        cassette = Keyword.get(options, :cassette, Cassette)

        location =
          "#{cassette.config.base_url}/login?service=#{URI.encode(service(conn, options))}"

        conn
        |> put_resp_header("location", location)
        |> send_resp(307, "")
        |> halt
      end

      @doc """
      Renders a Forbidden response
      """
      @spec invalid_authentication(conn :: Conn.t(), options :: term) :: Conn.t()
      def invalid_authentication(conn, _options) do
        conn
        |> send_resp(403, "Forbidden")
        |> halt
      end

      @doc """
      Get the current user from session and the ticket from the query string
      """
      @spec user_or_token(conn :: Conn.t(), options :: term) ::
              {User.t() | nil, {:ok, String.t()} | :error}
      def user_or_token(conn, _options) do
        {get_session(conn, "cas_user"), Map.fetch(conn.query_params, "ticket")}
      end

      @doc """
      Stores the current user in the session under the `cas_user` key
      """
      @spec user_authenticated(conn :: Conn.t(), user :: User.t(), options :: term) :: Conn.t()
      def user_authenticated(conn, user, _options) do
        put_session(conn, "cas_user", user)
      end

      @doc """
      Computes the service from the URL requested in the `conn` argument.
      It will remove the `ticket` from the query string paramaters since the ticket has not been generated with it.
      """
      @spec url(Conn.t(), term) :: String.t()
      def url(conn, _options) do
        [
          "#{conn.scheme}://#{conn.host}#{url_port_string(conn)}#{conn.request_path}",
          query_string(conn)
        ]
        |> Enum.reject(fn v -> is_nil(v) || v == "" end)
        |> Enum.join("?")
      end

      @spec query_string(Conn.t()) :: String.t()
      defp query_string(conn = %Conn{query_params: %Conn.Unfetched{aspect: :query_params}}) do
        query_string(Conn.fetch_query_params(conn))
      end

      defp query_string(conn) do
        conn.query_params
        |> Enum.reject(fn {k, _} -> k == "ticket" end)
        |> URI.encode_query()
      end

      @spec url_port_string(Conn.t()) :: String.t()
      defp url_port_string(%Conn{port: 80, scheme: :http}), do: ""
      defp url_port_string(%Conn{port: 443, scheme: :https}), do: ""
      defp url_port_string(conn = %Conn{}), do: ":#{conn.port}"

      defoverridable init: 1,
                     user_or_token: 2,
                     service: 2,
                     unauthenticated: 2,
                     invalid_authentication: 2,
                     user_authenticated: 3
    end
  end
end

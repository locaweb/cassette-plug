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
  """

  import Plug.Conn

  @spec init([]) :: []
  @doc "Initializes this plug"
  def init(options), do: options

  @spec service(Plug.Conn.t, term) :: String.t
  @doc """
  Fetches the service from the configuration of provided `:cassette` or the default `Cassette` module.
  """
  def service(_conn, options) do
    cassette = Keyword.get(options, :cassette, Cassette)
    cassette.config.service
  end

  @spec url(Plug.Conn.t, term) :: String.t
  @doc """
  Computes the service from the URL requested in the `conn` argument.
  It will remove the `ticket` from the query string paramaters since the ticket has not been generated with it.
  """
  def url(conn, _options) do
    query_string =
      conn.query_params
      |> Enum.reject(fn({k, _}) -> k == "ticket" end)
      |> URI.encode_query

    ["#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}", query_string]
    |> Enum.reject(fn(v) -> is_nil(v) || v == "" end)
    |> Enum.join("?")
  end

  @spec call(Plug.Conn.t, [cassette: Cassette.Support, service: ((Plug.Conn, term) -> String.t)]) :: Plug.Conn.t
  @doc """
  Runs this plug.

  Your custom Cassette module may be provided with the `:cassette` key. It will default to the `Cassette` module.
  """
  def call(conn, options) do
    cassette = Keyword.get(options, :cassette, Cassette)
    service = Keyword.get(options, :service, &url/2)

    case {get_session(conn, "cas_user"), conn.query_params["ticket"]} do
      {%Cassette.User{}, _} -> conn
      {nil, nil} ->
        location = "#{cassette.config.base_url}/login?service=#{URI.encode(service.(conn, options))}"
        conn |> put_resp_header("location", location) |> send_resp(307, "") |> halt
      {nil, ticket} ->
        case cassette.validate(ticket, service.(conn, options)) do
          {:ok, user} -> put_session(conn, "cas_user", user)
          _ -> conn |> resp(403, "Forbidden") |> halt
        end
    end
  end
end

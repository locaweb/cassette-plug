defmodule Cassette.Plug.DefaultHandler do
  @moduledoc """
  Default implementation of the `Cassette.Plug.AuthenticationHandler` behaviour

  Assumptions for this module:

  * The ticket is provided by a query string parameter called `ticket`
  * When not authenticated the user will be directed to the CAS server using the current url for the `service`
  * If the ticket is invalid or expired the user will be presented with a simple "Forbidden" response

  """
  use Cassette.Plug.AuthenticationHandler
end

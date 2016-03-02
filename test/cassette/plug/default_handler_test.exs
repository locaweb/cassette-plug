defmodule Cassette.Plug.DefaultHandlerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import RemovesTicket

  test "url/2 builds the current request url" do
    conn = %{conn(:get, "/foo?bar=42") | host: "example.org"} |> Plug.Conn.fetch_query_params

    assert Cassette.Plug.DefaultHandler.url(conn, []) == "http://example.org:80/foo?bar=42"
  end

  test_removes_ticket("/", "/")
  test_removes_ticket("/?ticket=x", "/")
  test_removes_ticket("/?master=1&ticket=x", "/?master=1")
  test_removes_ticket("/foo", "/foo")
  test_removes_ticket("/foo?bar=42", "/foo?bar=42")
  test_removes_ticket("/foo?bar=42&ticket=master", "/foo?bar=42")
  test_removes_ticket("/foo?ticket=master", "/foo")
  test_removes_ticket("/foo?ticket=master&bar=42", "/foo?bar=42")
end

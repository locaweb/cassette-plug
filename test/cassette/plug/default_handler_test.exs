defmodule Cassette.Plug.DefaultHandlerTest do
  use ExUnit.Case, async: true
  use Plug.Test

  import RemovesTicket

  test "url/2 builds the current request url" do
    conn = %{conn(:get, "/foo?bar=42") | host: "example.org"} |> Plug.Conn.fetch_query_params()

    assert Cassette.Plug.DefaultHandler.url(conn, []) == "http://example.org/foo?bar=42"
  end

  test "url/2 does not break if query_parameters are unfetched" do
    conn = %{conn(:get, "/foo?bar=42") | host: "example.org"}

    assert Cassette.Plug.DefaultHandler.url(conn, []) == "http://example.org/foo?bar=42"
  end

  test "url/2 does not add port when it is the default for http" do
    conn = %{conn(:get, "/foo") | host: "example.org"}

    assert Cassette.Plug.DefaultHandler.url(conn, []) == "http://example.org/foo"
  end

  test "url/2 does adds the port when it is not the default for http" do
    conn = %{conn(:get, "/foo") | host: "example.org", port: 8080}

    assert Cassette.Plug.DefaultHandler.url(conn, []) == "http://example.org:8080/foo"
  end

  test "url/2 does not add port when it is the default for https" do
    conn = %{conn(:get, "/foo") | scheme: :https, port: 443, host: "example.org"}

    assert Cassette.Plug.DefaultHandler.url(conn, []) == "https://example.org/foo"
  end

  test "url/2 adds port when it is not the default for https" do
    conn = %{conn(:get, "/foo") | scheme: :https, port: 8443, host: "example.org"}

    assert Cassette.Plug.DefaultHandler.url(conn, []) == "https://example.org:8443/foo"
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

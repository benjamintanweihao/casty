defmodule IcyResponseTest do
  use ExUnit.Case

  alias Icy.Parser, as: P

  test "parse a complete request" do
    request = "GET / HTTP/1.0\r\nkey: value\r\n\r\n"

    {:ok, [{:key, "value"}], ""} = P.request(request)
  end

  test "parse a complete request with more than one key-value pair" do
    request = "GET / HTTP/1.0\r\nHost: example.com\r\nIcy-MetaData: 1\r\n\r\n"

    assert {:ok, [Host: "example.com", "Icy-MetaData": "1"], ""} == P.request(request)
  end

  test "parse an incomplete request" do
    request = "GET / HTTP/1.0\r\nkey: value\r\n"
    {:more, _} = P.request(request)
  end

  test "parse metaint given a request with a complete header" do
    request = "ICY 200 OK\r\nicy-name: KISS ARMY\r\nicy-metaint: 32768\r\n\r\n"
    {:ok, 'ICY 200 OK', r1} = P.line(request)
    {:ok, headers, _} = P.header(r1)

    assert P.metaint(headers) == 32768
  end

  test "returns a default metaint given a valid header" do
    request = "ICY 200 OK\r\nicy-name: KISS ARMY\r\n\r\n"
    {:ok, 'ICY 200 OK', r1} = P.line(request)
    {:ok, headers, _} = P.header(r1)

    assert P.metaint(headers) == 8192
  end

  test "can reply" do
    {:ok, data, _h} = Icy.Parser.reply("ICY 200 OK\r\nicy-me taint: 5\r\n\r\n123")
    {:more, _} = data.() 
  end

end

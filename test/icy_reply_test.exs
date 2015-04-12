defmodule IcyReplyTest do
  use ExUnit.Case

  test "process headers" do

    header =
      [{:'icy-notice',  "This stream requires Winamp .."},
      {:'icy-name',     "Virgin Radio ..."},
      {:'icy-genre',    "Adult Pop Rock"},
      {:'icy-url',      "http://www.virginradio.co.uk/"},
      {:'content-type', "audio/mpeg"},
      {:'icy-pub',      "1"},
      {:'icy-metaint',  "8192"},
      {:'icy-br',       "128"}]

    expected = 
    "icy-notice:This stream requires Winamp ..\r\nicy-name:Virgin Radio ...\r\nicy-genre:Adult Pop Rock\r\nicy-url:http://www.virginradio.co.uk/\r\ncontent-type:audio/mpeg\r\nicy-pub:1\r\nicy-metaint:8192\r\nicy-br:128\r\n\r\n"

    assert expected == Icy.Reply.header_to_string(header)
  end

  test "padding that is a multiple of 16" do
    expected = {2, "KISS - I was made for loving you"}
    assert expected == Icy.Reply.padding("KISS - I was made for loving you")

  end

  test "padding that is not a multiple of 16" do
    expected = {3, "KISS - I was made for loving youuu00000000000000"}

    actual = Icy.Reply.padding("KISS - I was made for loving youuu")
    assert expected == actual
  end


end

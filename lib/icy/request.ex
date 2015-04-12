defmodule Icy.Request do

  def send(host, feed, sender) do
    request = "GET #{feed} HTTP/1.0\r\n" <>
    "Host: #{host} \r\n"       <>
    "User-Agent: Casty\r\n"    <>
    "Icy-MetaData: 1\r\n\r\n"

    sender.(request)
  end

end



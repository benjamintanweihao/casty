defmodule Icy.Reply do

  def send(header, sender) do
    status = "ICY 200 OK\r\n"
    reply  = status <> header_to_string(header)

    sender.(reply)
  end

  def header_to_string([]), do: "\r\n"
  def header_to_string([{name, value} | rest]) do
    "#{name}:#{value}\r\n" <> header_to_string(rest)
  end
  def header_to_string(x), do: IO.puts "hs: #{inspect x}"

  def send_data({audio, metadata}, sender) do
    send_audio(audio, sender)
    send_metadata(metadata, sender)
  end

  def send_audio(audio, sender) do
    sender.(audio)
  end

  def send_metadata(metadata, sender) do
    sender.(padding(metadata))
  end

  def padding(metadata) do
    l = String.length(metadata)
    k = l |> div(16)
    r = l |> rem(16)

    if r > 0 do
      {k+1, String.ljust(metadata, 16*(k+1), ?0)}
    else 
    {k, metadata}
    end
  end

end


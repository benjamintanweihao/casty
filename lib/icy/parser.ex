defmodule Icy.Parser do
  alias String, as: S

  def request(bin) do
    case line(bin) do
      {:ok, 'GET / HTTP/1.0', r1} ->
        case header(r1) do
          {:ok, header, r2} ->
            {:ok, header, r2}

          :more ->
            {:more, fn(more) -> request(bin <> more) end}
        end

      {:ok, 'GET / HTTP/1.1', r1} ->
        case header(r1) do
          {:ok, header, r2} ->
            {:ok, header, r2}

          :more ->
            {:more, fn(more) -> request(bin <> more) end}
        end

      {:ok, req, _} ->
        {:error, "invalid request: #{req}"}

      :more ->
        {:more, fn(more) -> request(bin <> more) end}
    end
  end

  def reply(bin) do
    case line(bin) do
      {:ok, 'ICY 200 OK', r1} ->
        IO.puts "replied!"
        case header(r1) do
          {:ok, header, r2} ->
            {:ok, fn -> data(r2, metaint(header)) end, header}

          :more ->
            {:more, fn(more) -> reply(bin <> more) end}

        end

      {:ok, reply, _} ->
        {:error, "invalid reply: #{reply}"}
  
      :more ->
        {:more, fn(more) -> reply(bin <> more) end}
    end
  end

  def line(request), do: line(request, [])
  def line(<<>>, _), do: :more
  def line("\r\n" <> rest, more) do
    {:ok, Enum.reverse(more), rest}
  end
  def line(<<char, rest::binary>>, more) do
    line(rest, [char|more])
  end

  def header(bin), do: header(bin, [])
  def header(bin, more) do
    case line(bin) do
      {:ok, [], rest} ->
        {:ok, header_encode(more, []), rest}
    
      {:ok, line, rest} ->
        header(rest, [line|more])
    
      :more -> 
        :more
    end
  end

  def header_encode([], headers), do: headers
  def header_encode([line|lines], headers) do
    [name, value] = S.split("#{line}", ":", parts: 2)
    header_encode(lines, [{S.to_atom(name), value}|headers])
  end

  def metaint([{:"icy-metaint", metaint}|_]) do
    S.to_integer(metaint)
  end

  def metaint([_|rest]), do: metaint(rest)
  def metaint([]), do: 8192

  def data(bin, metaint) do
    audio(bin, [], metaint, metaint) 
  end
  
  def audio(bin, so_far, n, m) do
    size = byte_size(bin)
    if size >= n do
      {chunk, rest} = S.split_at(bin, n)
      metadata(rest, Enum.reverse([chunk|so_far]), m)
    else
      {:more, fn(more) -> audio(more, [bin|so_far], n-size, m) end}
    end
  end

  def metadata(<<>>, audio, m) do
    {:more, fn(more) -> metadata(more, audio, m) end}
  end

  def metadata(bin, audio, m) do
    <<k::integer, r0::binary>> = bin
    size = byte_size(r0) 

    h = k * 16
    if size >= h do
      {padded, r2} = S.split_at(r0, h)
      meta = S.rstrip(padded, ?0) 
      {:ok, {audio, meta}, fn -> data(r2, m) end}
    else
      {:more, fn(more) -> metadata(bin <> more, audio, m) end}
    end
  end

end

defmodule Icy.Client do
  alias Icy.Reply
  @timeout 50000

  def init(proxy, port) do
    opts = [
      :binary,
      {:packet, 0}, 
      {:reuseaddr, true}, 
      {:active, true},   # socket process sends segments as they come
      {:nodelay, true}   # send segments asap
    ]

    {:ok, listen} = :gen_tcp.listen(port, opts) 
    {:ok, socket} = :gen_tcp.accept(listen)

    case read_request(socket) do
      {:ok, _, _} ->
        case connect(proxy) do
          {:ok, n, context} ->
            send_reply(context, socket)
            {:ok, msg} = loop(n, socket)
            IO.puts "client: terminating #{msg}"

          {:error, error} ->
            IO.puts "client: #{inspect error}"
            
        end

      {:error, error} ->
        IO.puts "client: #{inspect error}"
    end
  end

  def connect(proxy) do
    send(proxy, {:request, self})

    receive do
      {:reply, n, context} ->
        {:ok, n, context}

      after @timeout ->
        {:error, "time out"}
    end
  end

  def loop(_, socket) do
    receive do
      {:data, n, data} ->
        send_data(data, socket) 
        loop(n+1, socket)
  
      {:tcp_closed, _socket} ->
        {:ok, "player closed connection"}

      after @timeout ->
        {:ok, "time out"}
    end
  end

  def send_data(data, socket) do
    Reply.send_data(data, fn(bin) -> :gen_tcp.send(socket, bin) end)
  end

  def send_reply(context, socket) do
    Reply.send(context, fn(bin) -> :gen_tcp.send(socket, bin) end)
  end

  def reader(cont, socket) do
    case cont.() do
      {:ok, parsed, rest} ->
        {:ok, parsed, rest}

      {:more, fun} ->
        receive do
          {:tcp, socket, more} ->
            reader(fn -> fun.(more) end, socket)

          {:tcp_closed, _socket} ->
            {:error, "server closed connection"}
          
        after @timeout ->
          {:error, "time out"}
        end
        
      {:error, error} ->
        {:error, error}
    end
  end

  def read_request(socket) do
    reader(fn -> Icy.Parser.request(<<>>) end, socket)
  end

end

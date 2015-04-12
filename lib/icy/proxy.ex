defmodule Icy.Proxy do
  
  alias Icy.Request
  alias Icy.Parser
  @timeout 50000

  def init(cast) do
    receive do
      {:request, client} ->
        IO.puts "proxy: received request #{inspect client}"
        ref = Process.monitor(client)

        IO.puts "proxy cast: #{inspect cast}"
        case attach(cast, ref) do
          {:ok, stream, cont, context} ->
            IO.puts "proxy: attached"
            send(client, {:reply, 0, context})
            {:ok, msg} = loop(cont, 0, stream, client, ref)
            IO.puts "proxy: terminating #{inspect msg}"
          
          {:error, error} ->
            IO.puts "proxy: error #{inspect error}"
        end
    end
  end

  def loop(cont, n, stream, client, ref) do
    case reader(cont, stream, ref) do
      {:ok, data, rest} ->
        send(client, {:data, n, data})
        loop(rest, n+1, stream, client, ref)

      {:error, error} ->
        {:ok, error}
    end
  end

  def attach({:cast, host, port, feed}, ref) do
    opts = [:binary, packet: 0]
    IO.puts "proxy: attaching to #{host}:#{port}"
    case :gen_tcp.connect(host, port, opts) do
      {:ok, stream} ->
        IO.puts "proxy: connected"
        case request(host, feed, stream) do
          :ok ->
            IO.puts "proxy: sending request"
            case reply(stream, ref) do
              {:ok, cont, context} ->
                {:ok, stream, cont, context} 
    
              {:error, error} ->
                {:error, error}
            end

          _ ->
            {:error, "unable to send request"}
        end

      _ -> 
        {:error, "unable to connect to the server"}
    end
  end

  def reader(cont, stream, ref) do
    case cont.() do
      {:ok, parsed, rest} ->
        {:ok, parsed, rest}

      {:more, fun} ->
        receive do
          {:tcp, stream, more} ->
            reader(fn -> fun.(more) end, stream, ref)

          {:tcp_closed, _stream} ->
            {:error, "icy server closed connection"}

          {:DOWN, _ref, :process, _, _} ->
            {:error, "client died"}

        after @timeout ->
          {:error, "time out"}
          
        end
    end
  end

  def request(host, feed, stream) do
    Request.send(host, feed, fn(bin) -> :gen_tcp.send(stream, bin) end)
  end
          
  def reply(stream, ref) do
    reader(fn -> Parser.reply(<<>>) end, stream, ref)
  end

end

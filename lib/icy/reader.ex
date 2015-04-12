defmodule Icy.Reader do

  def reader(parser, socket) do
    case parser.parse() do
      {:ok, parsed, rest} ->
        {:ok, parsed, rest}
        
      {:more, cont} ->
        receive do
          {:tcp, socket, more} ->
            reader(fn -> cont.(more) end, socket)

          {:tcp_closed, _socket} ->
            {:error, "server closed connect"}

          :stop ->
            :aborted
        end
      
        {:error, error} -> 
          {:error, error}
    end
  end

end

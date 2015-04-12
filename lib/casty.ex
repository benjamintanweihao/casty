defmodule Casty do
  
  def start do
    # NOTE: must be char list... wtf
    cast = {:cast, 'shoutcast.unitedradio.it', 1307, "/"}
    proxy = spawn(Icy.Proxy, :init, [cast])

    # Connect to port 8080
    spawn(Icy.Client, :init, [proxy, 8080])
  end
  
end

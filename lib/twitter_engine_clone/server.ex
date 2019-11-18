defmodule Twitter.Server do
    use GenServer
    require Logger

    def start_link() do
        GenServer.start_link(__MODULE__, :ok)
    end

    def init(:no_args) do
        
    end
end
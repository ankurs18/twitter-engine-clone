defmodule Twitter.Client  do
    use GenServer, restart: :transient
  
    def start_link(id) do
      GenServer.start_link(__MODULE__, id)
    end
  
    def init(id) do
      id = id
      {:ok, {id, %{}, false}}
    end
  
    def fetch_id(pid), do: GenServer.call(pid, {:fetch_id}, :infinity)
end        
defmodule Twitter.Server do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_args)
  end

  def init(:no_args) do
    IO.puts("init")
    :ets.new(:users, [:set, :public, :named_table])
    :ets.new(:active_users, [:set, :public, :named_table])
    {:ok, {}}
  end

  def register_user(pid, user_id), do: GenServer.call(pid, {:register_user, user_id})
  def follow_user(pid, follower_id, following_id), do: GenServer.call(pid, {:follow_user, follower_id, following_id})

  def handle_call({:register_user, user_id}, _from, _state) do
    is_inserted = :ets.insert_new(:users, {user_id, %{}})
    if is_inserted==true do
        pid = Twitter.UserSupervisor.start_worker(user_id)
        :ets.insert(:active_users, {user_id, pid})
        {:reply, {:success, pid}, {}}
    else
        {:reply, {:duplicate_user_error}, {}}
    end
  end

  def handle_call({:follow, follower_id, following_id}, _from, _state) do
    
  end
end

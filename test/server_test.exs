defmodule TwitterTest.Server do
  use ExUnit.Case
  doctest Twitter.Server

  setup do
    {:ok, _server_pid} = Twitter.Server.start_link(:no_args)
    client_name = "test1"
    {:ok, client_pid} = Twitter.Client.start_link(client_name)
    {:ok, client_name: client_name, client_pid: client_pid}
  end

  test "Register User", state do
    assert Twitter.Server.register_user(state[:client_name], state[:client_pid]) == {:success}
    [{user, _}] = :ets.lookup(:users, state[:client_name])
    assert user == state[:client_name]
  end

  test "Register User again -> duplicate user error", state do
    assert Twitter.Server.register_user(state[:client_name], state[:client_pid]) == {:success}

    assert Twitter.Server.register_user(state[:client_name], state[:client_pid]) ==
             {:duplicate_user_error}
  end

  test "Login User", state do
    assert Twitter.Server.register_user(state[:client_name], state[:client_pid]) == {:success}
  end

  # right now we are not allowing active user to login again
  test "Login user -> already logged-in ", state do
    assert Twitter.Server.register_user(state[:client_name], state[:client_pid]) == {:success}
  end
end

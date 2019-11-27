defmodule TwitterTest.Client do
  use ExUnit.Case
  doctest Twitter.Client

  setup do
    {:ok, _server_pid} = Twitter.Server.start_link(:no_args)
    client1_name = "test1"
    client2_name = "test2"
    {:ok, client1_pid} = Twitter.Client.start_link(client1_name)
    {:ok, client2_pid} = Twitter.Client.start_link(client2_name)

    {:ok,
     client1_name: client1_name,
     client2_name: client2_name,
     client1_pid: client1_pid,
     client2_pid: client2_pid}
  end

  test "retweeting ", state do
    Twitter.Server.register_user(state[:client1_name], state[:client1_pid])
    Twitter.Server.register_user(state[:client2_name], state[:client2_pid])
    message = "Hi there!"
    Twitter.Client.follow(state[:client2_pid], state[:client1_name])
    # client1 sends the message
    Twitter.Client.tweet(state[:client1_pid], message)
    :sys.get_state(state[:client1_pid])
    :sys.get_state(:server)
    {:tweets, [{id, _, _, _}]} = Enum.at(:sys.get_state(state[:client2_pid]), 0)
    Twitter.Client.retweet(state[:client2_pid], id)
    :sys.get_state(state[:client2_pid])
    :sys.get_state(:server)
    [[tweet_id]] = :ets.match(:tweets, {:_, message, state[:client2_name], :"$1"})
    assert tweet_id == id
  end

  test "live update on mention", state do
    Twitter.Server.register_user(state[:client1_name], state[:client1_pid])
    Twitter.Server.register_user(state[:client2_name], state[:client2_pid])
    message = "Hi there! @#{state[:client2_name]}"
    Twitter.Client.tweet(state[:client1_pid], message)
    :sys.get_state(state[:client1_pid])
    :sys.get_state(:server)
    [[tweet_id]] = :ets.match(:tweets, {:"$1", message, state[:client1_name], :_})
    {:tweets, [{id, _, _, _}]} = Enum.at(:sys.get_state(state[:client2_pid]), 0)
    assert tweet_id == id
  end

  test "live update on mention updating users table", state do
    Twitter.Server.register_user(state[:client1_name], state[:client1_pid])
    Twitter.Server.register_user(state[:client2_name], state[:client2_pid])
    message = "Hi there! @#{state[:client2_name]}"
    Twitter.Client.tweet(state[:client1_pid], message)
    :sys.get_state(state[:client1_pid])
    :sys.get_state(:server)
    [[tweet_id]] = :ets.match(:tweets, {:"$1", message, state[:client1_name], :_})
    [[id]] = :ets.match(:users, {state[:client2_name], %{:mentions => [:"$1"]}})
    # {:tweets, [{id, _, _, _}]} = Enum.at(:sys.get_state(state[:client2_pid]), 0)
    assert tweet_id == id
  end
end

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

  test "get subscribed users tweet in live feed", state do
    Twitter.Client.register(state[:client1_pid])
    Twitter.Client.register(state[:client2_pid])
    :sys.get_state(state[:client2_pid])
    message = "Hi there!"
    Twitter.Client.follow(state[:client2_pid], state[:client1_name])
    Twitter.Client.tweet(state[:client1_pid], message)
    :sys.get_state(state[:client1_pid])
    :sys.get_state(:server)
    [[{client2_id, _, _, _}]] = Twitter.Client.get_tweets(state[:client2_pid], :subscribed)
    [{id, _, _, _}] = Map.get(:sys.get_state(state[:client2_pid]), :tweets)
    # if queried tweet id is same as the id present in the state
    assert id == client2_id
    # if sent tweet id by client 1 is same as the id present in the state of client 2
    [[tweet_id]] = :ets.match(:users, {state[:client1_name], %{:tweet_ids => [:"$1"]}})

    assert id == tweet_id
  end

  test "retweeting ", state do
    Twitter.Client.register(state[:client1_pid])
    Twitter.Client.register(state[:client2_pid])
    :sys.get_state(state[:client2_pid])
    message = "Hi there!"
    Twitter.Client.follow(state[:client2_pid], state[:client1_name])
    # client1 sends the message
    Twitter.Client.tweet(state[:client1_pid], message)
    :sys.get_state(state[:client1_pid])
    :sys.get_state(:server)
    [{id, _, _, _}] = Map.get(:sys.get_state(state[:client2_pid]), :tweets)
    Twitter.Client.retweet(state[:client2_pid], id)
    :sys.get_state(state[:client2_pid])
    :sys.get_state(:server)
    [[tweet_id]] = :ets.match(:tweets, {:_, message, state[:client2_name], :"$1"})
    assert tweet_id == id
  end

  test "live update on mention", state do
    Twitter.Client.register(state[:client1_pid])
    Twitter.Client.register(state[:client2_pid])
    message = "Hi there! @#{state[:client2_name]}"
    Twitter.Client.tweet(state[:client1_pid], message)
    :sys.get_state(state[:client1_pid])
    :sys.get_state(:server)
    [[tweet_id]] = :ets.match(:tweets, {:"$1", message, state[:client1_name], :_})
    {:tweets, [{id, _, _, _}]} = Enum.at(:sys.get_state(state[:client2_pid]), 0)
    assert tweet_id == id
  end

  test "live update on mention updating users table", state do
    Twitter.Client.register(state[:client1_pid])
    Twitter.Client.register(state[:client2_pid])
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

defmodule TwitterTest.Server do
  use ExUnit.Case
  doctest Twitter.Server

  setup do
    {:ok, _} = Twitter.Server.start_link(:no_args)
    client = "Aditya"
    {:ok, client_pid} = Twitter.Client.start_link(client)
    client2 = "Truc"
    {:ok, client_pid2} = Twitter.Client.start_link(client2)
    {:ok, client: client, client_pid: client_pid, client2: client2, client_pid2: client_pid2}
  end

  test "Register User", state do
    assert Twitter.Server.register_user(state[:client], state[:client_pid]) == {:success}
    [{username, _}] = :ets.lookup(:users, state[:client])
    assert username == state[:client]
  end

  test "Register User again -> duplicate user error", state do
    assert Twitter.Server.register_user(state[:client], state[:client_pid]) == {:success}
    assert elem(Enum.at(:ets.lookup(:active_users, state[:client]), 0), 0) == state[:client]

    assert Twitter.Server.register_user(state[:client], state[:client_pid]) ==
             {:duplicate_user_error}
  end

  # asserting the value of the client's pid in the active_users table;
  # this table contains the pid of all logged in users
  test "Login User", state do
    Twitter.Server.register_user(state[:client], state[:client_pid])
    [tup] = :ets.lookup(:active_users, state[:client])
    assert elem(tup, 1) == state[:client_pid]
  end

  test "Logout user", state do
    Twitter.Server.register_user(state[:client], state[:client_pid])
    [lookup] = :ets.lookup(:active_users, state[:client])
    assert elem(lookup, 1) == state[:client_pid]
    Twitter.Server.logout_user(state[:client])
    :sys.get_state(:server)
    lookup2 = :ets.lookup(:active_users, state[:client])
    assert lookup2 == []
  end

  test "Delete user account", state do
    Twitter.Server.register_user(state[:client], state[:client_pid])
    Twitter.Server.delete_account(state[:client])
    :sys.get_state(:server)
    assert :ets.lookup(:users, state[:client]) == []
    assert :ets.lookup(:active_users, state[:client]) == []
  end

  test "Follow user failure -> non existant user", state do
    Twitter.Server.register_user(state[:client], state[:client_pid])
    assert Twitter.Server.follow_user(state[:client], "alin_dobra") == {:failure, :user_not_found}
  end

  test "Follow user success", state do
    Twitter.Server.register_user(state[:client], state[:client_pid])
    Twitter.Server.register_user(state[:client2], state[:client_pid2])
    assert Twitter.Server.follow_user(state[:client], state[:client2]) == {:success, nil}
    [{_, client1_map}] = :ets.lookup(:users, state[:client])

    assert Enum.find_index(Map.get(client1_map, :following), fn x -> x == state[:client2] end) !=
             nil

    [{_, client2_map}] = :ets.lookup(:users, state[:client2])

    assert Enum.find_index(Map.get(client2_map, :followers), fn x -> x == state[:client] end) !=
             nil
  end

  test "Tweet (simple)", state do
    Twitter.Server.register_user(state[:client], state[:client_pid])
    Twitter.Server.tweet("demo tweet", state[:client])
    :sys.get_state(:server)
    [[tweetid, tweet]] = :ets.match(:tweets, {:"$1", :"$2", state[:client], :_})
    [{_, client_map}] = :ets.lookup(:users, state[:client])
    assert tweet == "demo tweet"
    assert Enum.find_index(Map.get(client_map, :tweet_ids), fn x -> x == tweetid end) != nil
  end

  test "Tweet (mention)", state do
    Twitter.Server.register_user(state[:client], state[:client_pid])
    Twitter.Server.register_user(state[:client2], state[:client_pid2])
    Twitter.Server.tweet("demo tweet @#{state[:client2]}", state[:client])
    Twitter.Server.tweet("demo2 tweet2 @#{state[:client2]}", state[:client])
    :sys.get_state(:server)
    tweet_ids = :ets.match(:tweets, {:"$1", :_, state[:client], :_})
    tweet_ids = List.flatten(tweet_ids)
    # IO.inspect({"flat", tweet_ids})
    [{_, client2_map}] = :ets.lookup(:users, state[:client2])
    list_from_ets = Map.get(client2_map, :mentions)
    assert Enum.sort(list_from_ets) == Enum.sort(tweet_ids)
  end

  test "Tweet (hashtag)", state do
    Twitter.Server.register_user(state[:client], state[:client_pid])
    Twitter.Server.tweet("demo tweet #demotag", state[:client])
    :sys.get_state(:server)
    [[tweetid]] = :ets.match(:tweets, {:"$1", :_, state[:client], :_})
    [{_, list}] = :ets.lookup(:hashtags, "demotag")
    assert Enum.find_index(list, fn x -> x == tweetid end) != nil
  end

  test "Query tweets (hashtag)", state do
    Twitter.Server.register_user(state[:client], state[:client_pid])
    Twitter.Server.tweet("demo tweet #demotag", state[:client])
    Twitter.Server.register_user(state[:client2], state[:client_pid2])
    Twitter.Server.tweet("demo tweet 2 #demotag", state[:client2])
    :sys.get_state(:server)

    list_from_server =
      Enum.reduce(Twitter.Server.query_hashtag("demotag"), [], fn {id, _, _, _}, acc ->
        [id | acc]
      end)

    [{_, list_from_ets}] = :ets.lookup(:hashtags, "demotag")
    assert list_from_ets == list_from_server
  end

  test "Query tweet (mention)", state do
    Twitter.Server.register_user(state[:client], state[:client_pid])
    Twitter.Server.register_user(state[:client2], state[:client_pid2])
    Twitter.Server.tweet("demo tweet @#{state[:client2]}", state[:client])
    Twitter.Server.tweet("demo2 tweet2 @#{state[:client2]}", state[:client])
    :sys.get_state(:server)
    :sys.get_state(state[:client_pid2])

    list_from_server =
      Enum.reduce(Twitter.Server.query_mentions(state[:client2]), [], fn {id, _, _, _}, acc ->
        [id | acc]
      end)

    [{_, client2_map}] = :ets.lookup(:users, state[:client2])
    list_from_ets = Map.get(client2_map, :mentions)
    assert list_from_ets == list_from_server
  end

  test "Query tweets (own)", state do
    Twitter.Server.register_user(state[:client], state[:client_pid])
    Twitter.Server.tweet("demo tweet", state[:client])
    Twitter.Server.tweet("demo tweet2", state[:client])
    :sys.get_state(:server)

    list_from_server =
      Enum.reduce(Twitter.Server.query_own_tweets(state[:client]), [], fn {_, tweet, _, _}, acc ->
        [tweet|acc]
      end)
    
    assert Enum.find_index(list_from_server, fn x -> x=="demo tweet"end) != nil
    assert Enum.find_index(list_from_server, fn x -> x=="demo tweet2"end) != nil
  end
end

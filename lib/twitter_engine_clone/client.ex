defmodule Twitter.Client do
  use GenServer, restart: :transient
  require Logger

  def start_link(username) do
    GenServer.start_link(__MODULE__, username)
  end

  def init(username) do
    username = username
    {:ok, %{:username => username}}
  end

  def get_username(pid), do: GenServer.call(pid, {:get_username}, :infinity)

  def register(pid), do: GenServer.cast(pid, {:register})

  def login(pid), do: GenServer.cast(pid, {:login})

  def logout(pid), do: GenServer.cast(pid, {:logout})

  def delete_account(pid), do: GenServer.cast(pid, {:delete_account})

  def tweet(pid, message), do: GenServer.cast(pid, {:tweet, message})

  def follow(pid, follower_name), do: GenServer.cast(pid, {:follow, follower_name})

  def unfollow(pid, name), do: GenServer.cast(pid, {:unfollow, name})

  def get_tweets(pid, {:hashtags, data}), do: GenServer.cast(pid, {:get_tweets, :hashtag, data})

  def get_tweets(pid, type), do: GenServer.cast(pid, {:get_tweets, type, nil})

  def distribute_live(pid, tweet, tweet_id),
    do: GenServer.cast(pid, {:distribute_live, tweet, tweet_id})

  def handle_cast({:distribute_live, tweet, tweet_id}, state) do
    tweets_list = Map.get(state, :tweets, [])

    {:noreply, Map.put(state, :tweets, [{tweet_id, tweet} | tweets_list])}
  end

  def handle_cast({:register}, state) do
    username = Map.get(state, :username)
    Logger.debug("Registering #{username} to the server")

    case Twitter.Server.register_user(username, self()) do
      :duplicate_user_error -> IO.inspect("Client ID already exists")
      _ -> Logger.debug("#{username} registered")
    end

    {:noreply, state}
  end

  def handle_cast({:login}, state) do
    username = Map.get(state, :username)
    Logger.debug("login #{username} detail to the server")
    Twitter.Server.login_user(username, self())
    {:noreply, state}
  end

  def handle_cast({:logout}, state) do
    username = Map.get(state, :username)
    Logger.debug("loging out #{username}")
    Twitter.Server.logout_user(username)
    {:noreply, state}
  end

  def handle_cast({:delete_account}, state) do
    username = Map.get(state, :username)
    Logger.debug("deleting #{username} from the server")
    # Twitter.Server.delete_account(server, username, self())
    {:noreply, state}
  end

  def handle_cast({:tweet, message}, state) do
    username = Map.get(state, :username)
    Logger.debug("User #{username} tweeted #{message}")
    Twitter.Server.tweet(message, username)
    {:noreply, state}
  end

  def handle_cast({:follow, user}, state) do
    username = Map.get(state, :username)
    Logger.debug("#{username} follows #{user}")
    Twitter.Server.follow_user(username, user)
    {:noreply, state}
  end

  def handle_cast({:unfollow, user}, state) do
    username = Map.get(state, :username)
    Logger.debug("#{username} unfollows #{user}")
    # Twitter.Server.unfollow(username)
    {:noreply, state}
  end

  def handle_call({:get_tweets, type, data}, _from, state) do
    username = Map.get(state, :username)

    cond do
      type == :subscribed ->
        Twitter.Server.query_subscribed_tweets(username)
        Logger.debug("Get subscriber tweets of @#{data}")

      type == :hashtags ->
        Twitter.Server.query_hashtag(data)
        Logger.debug("Get tweets of @#{data}")

      type == :mentions ->
        Twitter.Server.query_mentions(username)
        Logger.debug("Get tweets of @#{data}")
    end

    {:reply, username, state}
  end
end

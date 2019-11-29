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

  def get_feed(pid), do: GenServer.call(pid, {:get_feed}, :infinity)

  def get_username(pid), do: GenServer.call(pid, {:get_username}, :infinity)

  def register(pid), do: GenServer.cast(pid, {:register})

  def login(pid), do: GenServer.cast(pid, {:login})

  def logout(pid), do: GenServer.cast(pid, {:logout})

  def delete_account(pid), do: GenServer.cast(pid, {:delete_account})

  def tweet(pid, message), do: GenServer.cast(pid, {:tweet, message})

  def retweet(pid, tweet_id), do: GenServer.cast(pid, {:retweet, tweet_id})

  def follow(pid, follower_name), do: GenServer.cast(pid, {:follow, follower_name})

  def unfollow(pid, name), do: GenServer.cast(pid, {:unfollow, name})

  def get_tweets(pid, :hashtags, data), do: GenServer.call(pid, {:get_tweets, :hashtags, data})

  def get_tweets(pid, type), do: GenServer.call(pid, {:get_tweets, type, nil})

  def distribute_live(pid, tweet),
    do: GenServer.cast(pid, {:distribute_live, tweet})

  def handle_cast({:distribute_live, tweet}, state) do
    username = Map.get(state, :username)
    Logger.debug("Notified to live user @#{username}")
    tweets_list = Map.get(state, :tweets, [])

    {:noreply, Map.put(state, :tweets, [tweet | tweets_list])}
  end

  def handle_cast({:register}, state) do
    username = Map.get(state, :username)
    Logger.debug("Registering @#{username} to the server")

    case Twitter.Server.register_user(username, self()) do
      :duplicate_user_error -> IO.inspect("Client ID already exists!")
      _ -> Logger.debug("#{username} registered")
    end

    {:noreply, state}
  end

  def handle_cast({:login}, state) do
    username = Map.get(state, :username)
    Logger.debug("Trying logging in #{username} #{inspect(self())} to the server")
    {status, list} = Twitter.Server.login_user(username, self())

    # IO.inspect(status)
    state =
      case status do
        :success ->
          Logger.debug("#{username} logged in #{inspect(self())}")
          Map.put(state, :tweets, list)

        :failure ->
          Logger.warn("FAILED! #{username} #{inspect(self())}")
          state
      end

    {:noreply, state}
  end

  def handle_cast({:logout}, state) do
    username = Map.get(state, :username)
    Logger.debug("loging out #{username}")
    Twitter.Server.logout_user(username)
    Process.exit(self(), :normal)
    {:noreply, state}
  end

  def handle_cast({:delete_account}, state) do
    username = Map.get(state, :username)
    Logger.debug("deleting #{username} from the server")
    Twitter.Server.delete_account(username)
    {:noreply, state}
  end

  def handle_cast({:tweet, message}, state) do
    username = Map.get(state, :username)
    Logger.debug("User #{username} tweeted #{message}")
    Twitter.Server.tweet(message, username)
    {:noreply, state}
  end

  def handle_cast({:retweet, tweet_id}, state) do
    username = Map.get(state, :username)
    Logger.debug("User #{username} retweeted #{tweet_id}")
    Twitter.Server.retweet(tweet_id, username)
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
        Logger.debug("Get subscriber tweets")
        {:reply, Twitter.Server.query_subscribed_tweets(username), state}

      type == :hashtags ->
        Logger.debug("Get tweets of ##{data}")
        len = String.length(data)
        data = String.slice(data, 1..(len - 1))
        {:reply, Twitter.Server.query_hashtag(data), state}

      type == :mentions ->
        Logger.debug("Get tweets of @#{data}")
        {:reply, Twitter.Server.query_mentions(username), state}
    end
  end

  def handle_call({:get_feed}, _from, state) do
    feeds = Map.get(state, :tweets)
    {:reply, feeds, state}
  end
end

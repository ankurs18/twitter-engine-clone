defmodule Twitter.Main do
  require Logger

  @chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890" |> String.split("", trim: true)
  @text "ABCDEFGHIJKLMNOPQRSTUVWXYZ " |> String.split("", trim: true)
  @hashtags [
    "#PyaarEkDhokaHai",
    "#UFL",
    "#PythonIsTheBest",
    "#MarvelVsDC",
    "#followme",
    "#SiliconValley",
    "#GOT",
    "#Avengers"
  ]
  def start(num_client \\ 10, num_message \\ 10) do
    :observer.start()
    {:ok, _server_pid} = Twitter.Server.start_link(:no_args)
    # Twitter.Server.register_user(server_pid, "ankur")

    clients =
      for _i <- 1..num_client do
        client_name = random_clientName(8)
        {:ok, client_pid} = Twitter.Client.start_link(client_name)
        Twitter.Client.register(client_pid)
        {client_name, client_pid}
      end

    for client <- clients do
      len = length(clients)
      # Make Followers
      number_of_followers = div(Enum.random(1..50) * len, 100)
      randomFollowing(client, clients, number_of_followers)
      # Tweet num_messages
      for(_ <- 1..num_message) do
        message = tweet_scenarios(Enum.random(1..4), clients -- [client])
        {_, client_pid} = client
        Twitter.Client.tweet(client_pid, message)
      end

      # some user goes offline
    end
  end

  def randomFollowing(client, clients, number_of_followers) do
    if(number_of_followers > 0) do
      random_user = Enum.random(clients)
      {_, client_pid} = client
      {random_user_name, _} = random_user
      Twitter.Client.follow(client_pid, random_user_name)
      randomFollowing(client, clients -- [random_user], number_of_followers - 1)
    end
  end

  def tweet_scenarios(scenario_num, clients) do
    cond do
      scenario_num == 1 ->
        Logger.debug("Scenario 1: Normal Message")
        random_message_generator()

      scenario_num == 2 ->
        Logger.debug("Scenario 2: Message with mentions")

        mentions = get_mentions(clients)

        Enum.reduce(mentions, random_message_generator(), fn mention, acc ->
          {client_name, _} = mention
          acc <> " @#{client_name}"
        end)

      scenario_num == 3 ->
        Logger.debug("Scenario 3: Message with hashtags")

        hashtags = get_hash_tags()

        Enum.reduce(hashtags, random_message_generator(), fn hashtag, acc ->
          acc <> " #{hashtag}"
        end)

      scenario_num == 4 ->
        Logger.debug("Scenario 4: Message with hashtags")
        mentions = get_mentions(clients, 1)
        hashtags = get_hash_tags(1)
        message = random_message_generator()

        message =
          Enum.reduce(hashtags, message, fn hashtag, acc ->
            acc <> " #{hashtag}"
          end)

        message =
          Enum.reduce(mentions, message, fn mention, acc ->
            {client_name, _} = mention
            acc <> " @#{client_name}"
          end)

        message
        # scenario_num == 5 -> IO.inspect("5. Retweet")
    end
  end

  def get_mentions(clients) do
    number_of_mentions = Enum.random(1..3)
    get_mentions(clients, number_of_mentions)
  end

  def get_mentions(clients, num) do
    Enum.uniq(
      Enum.reduce(1..num, [], fn _i, acc ->
        [Enum.random(clients) | acc]
      end)
    )
  end

  def get_hash_tags() do
    number_of_hastags = Enum.random(1..3)
    get_hash_tags(number_of_hastags)
  end

  def get_hash_tags(num) do
    Enum.reduce(1..num, [], fn _i, acc ->
      [Enum.random(@hashtags) | acc]
    end)
  end

  def random_clientName(length) do
    Enum.reduce(1..length, [], fn _i, acc ->
      [Enum.random(@chars) | acc]
    end)
    |> Enum.join("")
  end

  def random_message_generator() do
    Enum.reduce(1..100, [], fn _i, acc ->
      [String.downcase(Enum.random(@text)) | acc]
    end)
    |> Enum.join("")
  end
end

# [{_, pid}]= :ets.lookup(:active_users, "EBQHZMAC")
# Twitter.Client.get_tweets(pid, :mentions)
# Twitter.Main.start

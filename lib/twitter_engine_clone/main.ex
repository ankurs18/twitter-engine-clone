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
    start_time = System.monotonic_time(:millisecond)
    {:ok, _server_pid} = Twitter.Server.start_link(:no_args)

    IO.puts("Simulation starts...")

    clients =
      for _i <- 1..num_client do
        client_name = random_clientName(8)
        {:ok, client_pid} = Twitter.Client.start_link(client_name)
        Twitter.Client.register(client_pid)
        {client_name, client_pid}
      end

    clients
    |> Enum.with_index(1)
    |> Enum.each(fn {client,rank} ->      
      number_of_followers = div(num_client, rank) - 1
      IO.inspect({"rank", rank, num_client, number_of_followers})
      generate_random_followers(client, clients, number_of_followers)
    end)

    Task.start_link(__MODULE__, :check_status, [num_client * num_message])

    for client <- clients do

      Task.start_link(__MODULE__, :send_tweets, [
        client,
        clients,
        num_message
      ])
    end

    IO.puts("Time taken by simulator: #{start_time - System.monotonic_time(:millisecond)}")
  end

  def send_tweets(client, clients, num_messages) do
    if(num_messages > 0) do
      message = tweet_scenarios(Enum.random(1..4), clients -- [client])
      {client_name, client_pid} = client
      # if less than 2 then sleep
      if(trunc(:rand.uniform(10)) < 3) do
        Twitter.Client.logout(client_pid)
        Process.sleep(1000)
        {:ok, client_pid} = Twitter.Client.start_link(client_name)
        Twitter.Client.login(client_pid)
        send_tweets({client_name, client_pid}, clients, num_messages)
      else
        Twitter.Client.tweet(client_pid, message)
        Process.sleep(20)
        send_tweets(client, clients, num_messages - 1)
      end
    end
  end

  def check_status(total_tweets) do
    number_of_tweets = elem(Enum.at(:ets.info(:tweets), 8), 1)

    if(total_tweets >= number_of_tweets) do
      users = elem(Enum.at(:ets.info(:users), 8), 1)
      online_users = elem(Enum.at(:ets.info(:active_users), 8), 1)
      offline_users = users - online_users
      Logger.info("##############  Server Status  ################")
      Logger.info("Number of tweets sent: #{number_of_tweets}")
      Logger.info("Online users: #{online_users}")
      Logger.info("Offline users: #{offline_users}")
      Logger.info("###############################################")

      Process.sleep(1000)

      total_tweets =
        if(total_tweets == number_of_tweets) do
          IO.puts("Simulation Ends...")
          0
        else
          total_tweets
        end

      check_status(total_tweets)
    end
  end

  def generate_random_followers(client, clients, number_of_followers) do
    if(number_of_followers > 0) do
      random_user = Enum.random(clients)
      # {_, client_pid} = client
      # {random_user_name, _} = random_user
      {_, follower_pid} = random_user
      Twitter.Client.follow(follower_pid, elem(client,0))
      generate_random_followers(client, clients -- [random_user], number_of_followers - 1)
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

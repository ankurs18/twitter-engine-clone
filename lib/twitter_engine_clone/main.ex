defmodule Twitter.Main do
  require Logger

  @chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890" |> String.split("", trim: true)
  @text "ABCDEFGHIJKLMNOPQRSTUVWXYZ " |> String.split("", trim: true)
  @hashtags [
    "#COP5615isgreat",
    "#UFL",
    "#PythonVsElixir",
    "#MarvelVsDC",
    "#followme",
    "#SiliconValley",
    "#GOT",
    "#Avengers"
  ]

  def start(num_client \\ 10, num_message \\ 10) do
    # :observer.start()
    start_time = System.monotonic_time(:millisecond)
    {:ok, _server_pid} = Twitter.Server.start_link(:no_args)

    IO.puts("Simulation starts...")

    client_names = generate_client_id(num_client)
    # Clients are created and registered
    clients =
      for client_name <- client_names do
        # client_name = random_clientName(8)
        {:ok, client_pid} = Twitter.Client.start_link(client_name)
        Twitter.Client.register(client_pid)
        {client_name, client_pid}
      end

    # Followers are set to every client based on Zipf distribution
    clients
    |> Enum.with_index(1)
    |> Enum.each(fn {client, rank} ->
      number_of_followers =
        if rank == 1, do: div(num_client, rank) - 1, else: div(num_client, rank)

      Task.start_link(__MODULE__, :generate_random_followers, [
        client,
        clients,
        number_of_followers
      ])

      # generate_random_followers(client, clients, number_of_followers)
    end)

    IO.puts(
      "Time taken to generate followers: #{System.monotonic_time(:millisecond) - start_time}"
    )

    task = Task.async(__MODULE__, :log_server_status, [num_client * num_message])

    for client <- clients do
      Task.start_link(__MODULE__, :send_tweets, [
        client,
        clients,
        num_message
      ])
    end

    Task.await(task, :infinity)
    IO.puts("Time taken by simulator: #{System.monotonic_time(:millisecond) - start_time}")
  end

  def send_tweets(client, clients, num_messages) do
    if(num_messages > 0) do
      {client_name, client_pid} = client

      # if less than 2 then sleep
      if(trunc(:rand.uniform(10)) < 2) do
        Twitter.Client.logout(client_pid)

        Process.sleep(1000)
        {:ok, client_pid} = Twitter.Client.start_link(client_name)
        Twitter.Client.login(client_pid)
        send_tweets({client_name, client_pid}, clients, num_messages)
      else
        client_feed = Twitter.Client.get_feed(client_pid)

        scenario_type =
          if(client_feed != nil and length(client_feed) > 0) do
            Enum.random(1..5)
          else
            Enum.random(1..4)
          end

        message = tweet_scenarios(scenario_type, clients -- [client], client_feed)

        if(scenario_type == 5) do
          Twitter.Client.retweet(client_pid, message)
        else
          Twitter.Client.tweet(client_pid, message)
        end

        Process.sleep(30)
        send_tweets(client, clients, num_messages - 1)
      end
    end
  end

  def log_server_status(total_tweets) do
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

      Process.sleep(1500)

      if(total_tweets == number_of_tweets) do
        :ok
      else
        log_server_status(total_tweets)
      end

      # log_server_status(total_tweets)
    end
  end

  def generate_random_followers(client, clients, number_of_followers) do
    if(number_of_followers > 0) do
      random_user = Enum.random(clients)
      # {_, client_pid} = client
      # {random_user_name, _} = random_user
      {_, follower_pid} = random_user
      Twitter.Client.follow(follower_pid, elem(client, 0))
      generate_random_followers(client, clients -- [random_user], number_of_followers - 1)
    end
  end

  def tweet_scenarios(scenario_num, clients, client_feed) do
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
        Logger.debug("Scenario 4: Message with hashtags and mention")
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

      scenario_num == 5 ->
        Logger.debug("Scenario 5: Retweet")
        {id, _, _, _} = Enum.random(client_feed)
        id
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

  # def random_clientName(length) do
  #   Enum.reduce(1..length, [], fn _i, acc ->
  #     [Enum.random(@chars) | acc]
  #   end)
  #   |> Enum.join("")
  # end

  def random_message_generator() do
    Enum.reduce(1..100, [], fn _i, acc ->
      [String.downcase(Enum.random(@text)) | acc]
    end)
    |> Enum.join("")
  end

  defp generate_client_id(num_nodes) do
    Enum.reduce(1..num_nodes, MapSet.new(), &add_unique/2)
  end

  defp add_unique(_, acc) do
    new_set =
      MapSet.put(
        acc,
        Enum.join(Enum.reduce(1..8, [], fn _, gen -> [Enum.random(@chars) | gen] end))
      )

    if MapSet.size(acc) < MapSet.size(new_set), do: new_set, else: add_unique(1, acc)
  end
end

# [{_, pid}]= :ets.lookup(:active_users, "EBQHZMAC")
# Twitter.Client.get_tweets(pid, :mentions)
# Twitter.Main.start

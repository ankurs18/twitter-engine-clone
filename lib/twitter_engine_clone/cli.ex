defmodule Twitter.CLI do
  def run(argv) do
    argv
    |> parse_args
    |> process
  end

  defp parse_args(args) do
    parse = OptionParser.parse(args, aliases: [h: :help], switches: [help: :boolean])

    case parse do
      {[help: true], _, _} ->
        :help

      {_, [num_client, num_messages], _} ->
        {num_client, num_messages}

      _ ->
        :help
    end
  end

  defp process(:help) do
    IO.puts("""
    Usage: mix run twitter_engine_clone.exs <num_client> <num_messages>
    """)

    System.halt(0)
  end

  defp process({num_client, num_messages}) do
    num_client = String.to_integer(num_client)
    num_messages = String.to_integer(num_messages)

    if(num_messages <= 0) do
      IO.puts("""
        Error: Num of messages should be greater than zero
        Usage: mix run proj1.exs <num_client> <num_messages>
      """)

      System.halt(0)
    end

    if(num_client <= 1) do
      IO.puts("""
        Error: Num client should be greater than one
        Usage: mix run proj1.exs <num_client> <num_messages>
      """)

      System.halt(0)
    end

    Twitter.Main.start(num_client, num_messages)
  end
end

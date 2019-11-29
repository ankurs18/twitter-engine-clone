defmodule Twitter do
  @moduledoc """
  Documentation for Tapestry.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Tapestry.hello()
      :world

  """
  def main(args \\ []) do
    [num_client, num_messages] = args

    num_client = getParsesInteger(num_client)

    num_messages = getParsesInteger(num_messages)

    if(num_messages <= 0) do
      IO.puts("""
        Error: Num of messages should be greater than zero
        Usage: mix run proj1.exs <num_client> <num_messages>
      """)

      System.halt(0)
    end

    if(num_client <= 1) do
      IO.puts("""
        Error: Num of clients should be greater than one
        Usage: mix run proj1.exs <num_client> <num_messages>
      """)

      System.halt(0)
    end

    Twitter.Main.start(num_client, num_messages)
  end

  def getParsesInteger(val) do
    if(String.valid?(val)) do
      elem(Integer.parse(val), 0)
    else
      val
    end
  end
end

defmodule TwitterTest.Client do
  use ExUnit.Case
  doctest Twitter.Client

  test "greets the world" do
    assert TwitterEngineClone.hello() == :world
  end
end

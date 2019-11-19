defmodule Twitter.Main do
  def start do
    {:ok, server_pid} = Twitter.Server.start_link(:no_args)
    Twitter.Server.register_user(server_pid, "ankur")
  end
end

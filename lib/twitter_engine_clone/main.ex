defmodule Twitter.Main do
  def start(num_client \\3, num_message \\0) do
    :observer.start()
    {:ok, _} = Twitter.Server.start_link(:no_args)
    {:ok,rahul} = Twitter.Client.start_link("rahul")
    {:ok,ankur} = Twitter.Client.start_link("ankur")
    {:ok,abhi} = Twitter.Client.start_link("abhi")   
    
    Twitter.Client.register(rahul)
    Twitter.Client.register(ankur)
    Twitter.Client.register(abhi)

    Twitter.Client.follow(rahul, "abhi")
    Twitter.Client.follow(rahul, "ankur")
    Twitter.Client.follow(ankur, "abhi")
    Twitter.Client.follow(ankur, "rahul")
    Twitter.Client.follow(abhi, "rahul")
    Twitter.Client.follow(abhi, "ankur")

    Twitter.Client.tweet(rahul, "hi")
    Twitter.Client.tweet(ankur, "@abhi")
    Twitter.Client.tweet(ankur, "#abhi")

    




  end
end

# Adapter for a communication channel with a user (facebook bot, etc..)
defmodule Nono.Channel do
  alias Nono.Msg

  # Behavior the adapter needs to implement
  @type msg :: Nono.Msg.t
  @type user_id :: term
  @callback handle_notify(user_id, msg) :: :ok | {:error, term}

  # Send a message to the channel
  def notify(channel, user_id, msg = %Msg{}) do
    :ok = channel.handle_notify(user_id, msg)
  end
end

# Adapter for the communication with the team (slack bot)
defmodule Nono.Team do
  alias Nono.Msg

  # Behavior the adapter needs to implement
  @type msg :: Nono.Msg.t
  @type msg_type :: :question | :info
  @callback send_msg(msg_type, msg) :: :ok | {:error, term}

  # Ask a question
  def ask(team, msg = %Msg{}) do
    :ok = team.send_msg(:question, msg)
  end

  # Notify of a question and/or an answer
  def info(team, msg = %Msg{}) do
    :ok = team.send_msg(:info, msg)
  end
end

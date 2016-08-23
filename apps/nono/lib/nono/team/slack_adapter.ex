# Team communication via slack
defmodule Nono.Team.SlackAdapter do
  @behaviour Nono.Team
  @name :slack_adapter
  @channel "nono"

  alias Nono.Msg

  use Slack

  # Manual registering
  def start_link do
    case start_link(Application.fetch_env!(:slack, :token)) do
      {:ok, pid} ->
        # Manual register since the lib doesn't allow it the options
        Process.register(pid, @name)
        {:ok, pid}
      other -> other
    end
  end

  # No process termination ? Not cool bro, but whatever

  # Behavior implementation (client)
  def send_msg(type, message) do
    send(@name, {:message, type, message})
  end

  def message_content(type, msg = %Msg{from: :bot}) do
    "*<bot>* #{msg.content}"
  end

  def message_content(:info, msg = %Msg{from: {:user, uid}}) do
    "*<user:#{uid}>* #{msg.content}"
  end

  def message_content(:question, msg = %Msg{from: {:user, uid}}) do
    """
    @here <user:#{uid}> #{msg.content}
    To answer, msg me with "<user:#{uid}> [Your message]"
    """
  end

  # Message parsing
  # Looks for a pattern <@botname> <user:uid> Message
  def parse_message(content, bot_id) do
    regex = ~r/^<@#{bot_id}>\s+&lt;user:(\w+)&gt;\s+(.+)/
    case Regex.scan(regex, content) do
      [] -> :unimportant
      [[_content, uid, message]] -> {:answer, uid, message}
    end
  end

  # Watcher on the slack channel
  def handle_message(message = %{type: "message"}, slack) do
    case parse_message(message.text, slack.me.id) do
      :unimportant -> nil
      {:answer, uid, message} ->
        # Routing still not done for the rooms
        IO.puts "Got answer \"#{message}\" for #{uid}"
        # Room.answer uid, Msg.team(message)
    end

    {:ok}
  end
  def handle_message(_,_), do: :ok


  # Handle outgoing messages
  def handle_info({:message, type, msg}, slack) do
    channel = Application.fetch_env!(:slack, :channel)

    send_message(message_content(type, msg), channel, slack)

    {:ok}
  end
  def handle_info(_, _), do: :ok

end

defmodule NonoRoomTest do
  use ExUnit.Case
  doctest Nono.Room

  @uid "jdoe" # Mock user id

  alias Nono.Room
  alias Nono.Msg

  # Mock a bot interface, who can only answer to "foo" with "bar"
  defmodule MockBot do
    @behaviour Nono.Bot

    def answer_question(%Msg{content: "foo"}) do
      {:answer, Msg.bot("bar")}
    end

    def answer_question(_) do
      :no_answer
    end
  end

  # Mock a team interface, who will echo user messages
  defmodule MockTeam do
    @behaviour Nono.Team
    use GenServer

    # Forward received messages to the parent process
    def start_link do
      GenServer.start_link(__MODULE__, self, [name: :mock_team])
    end

    def send_msg(kind, msg) do
      GenServer.cast :mock_team, {kind, msg}
    end

    def handle_cast({kind, msg}, proxy) do
      send(proxy, {:team_proxy, kind, msg.from, msg.content})
      {:noreply, proxy}
    end
  end

  # Mock a channel, who will forward messages to the parent process
  defmodule MockChannel do
    @behaviour Nono.Channel
    use GenServer

    # Forward received messages to the parent process
    def start_link do
      GenServer.start_link(__MODULE__, self, [name: :mock_channel])
    end

    def handle_notify(user_id, msg) do
      GenServer.cast :mock_channel, {user_id, msg}
    end

    def handle_cast({user_id, msg}, proxy) do
      send(proxy, {:channel_proxy, user_id, msg.from, msg.content})
      {:noreply, proxy}
    end
  end

  setup do
    {:ok, _team} = MockTeam.start_link
    {:ok, _channel} = MockChannel.start_link
    {:ok, room} = Room.start_link(@uid, MockChannel, MockBot, MockTeam)
    [room: room]
  end

  describe "#ask" do
    test "when the bot has an answer", context do
      Room.ask(context[:room], Msg.user(@uid, "foo"))

      # The team has been notified
      assert_receive {:team_proxy, :info, {:user, @uid}, "foo"}
      assert_receive {:team_proxy, :info, :bot, "bar"}

      # The user received the answer
      assert_receive {:channel_proxy, @uid, :bot, "bar"}
    end

    test "when the bot has no answer", context do
      Room.ask(context[:room], Msg.user(@uid,"boo"))

      # The team has been notified
      assert_receive {:team_proxy, :question, {:user, @uid}, "boo"}
    end
  end

  describe "#answer" do
    test "answers are forwarded to the channel", context do
      Room.answer(context[:room], Msg.team("bar"))

      # The user received the answer
      assert_receive {:channel_proxy, @uid, :team, "bar"}
    end
  end

end

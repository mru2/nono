defmodule Nono.Room do
  @moduledoc """
  Handles an ongoing discussion with a person
  Receives messages, forward them to the bot or the team, and
  dispatches the answers
  """

  use GenServer

  alias Nono.Msg
  alias Nono.Bot
  alias Nono.Channel
  alias Nono.Team

  # --------------
  # Internal state
  # --------------
  defstruct [:user_id, :channel, :bot, :team]

  # ----------------
  # Client interface
  # ----------------

  # Initialize a new room for a given user
  def start_link(user_id, channel, bot, team) do
    # TODO: handle registration here
    GenServer.start_link(__MODULE__, %__MODULE__{
      user_id: user_id,
      channel: channel,
      bot: bot,
      team: team
    })
  end

  # Ask a question
  def ask(room, msg = %Msg{from: {:user, _uid}}) do
    GenServer.cast(room, {:question, msg})
  end

  # Dispatch a team answer
  def answer(room, msg = %Msg{from: :team}) do
    GenServer.cast(room, {:answer, msg})
  end

  # ---------------------
  # Server implementation
  # ---------------------

  # Handles a question, trying the bot first and fallbacking to the team
  def handle_cast({:question, question}, state) do
    # Try the bot
    case Bot.ask(state.bot, question) do
      # Nothing : forward to the team
      :no_answer ->
        Team.ask(state.team, question)
      # Else, send the answer, and notif the team
      {:answer, answer} ->
        Team.info(state.team, question)
        Team.info(state.team, answer)
        Channel.notify(state.channel, state.user_id, answer)
    end

    {:noreply, state}
  end

  # Handles an answer from the team, forwarding it to the user
  def handle_cast({:answer, answer = %Msg{from: :team}}, state) do
    # Forward the message to the user
    Channel.notify(state.channel, state.user_id, answer)

    {:noreply, state}
  end
end

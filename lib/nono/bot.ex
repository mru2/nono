# Generic interface for conversation bot
defmodule Nono.Bot do

  alias Nono.Msg

  # Behavior the adapter needs to implement (synchronous calls)
  @type msg :: Nono.Msg.t
  @callback answer_question(msg) :: {:answer, msg} | :no_answer

  def ask(bot, msg) do
    bot.answer_question(msg)
  end

end

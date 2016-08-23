defmodule Nono.Msg do
  @moduledoc """
  Represents a message
  Described by
  - who it is from (:bot, :team, {:user, uid})
  - its content
  - its date (:ts)
  """
  defstruct [:from, :content, :ts]

  def bot(content) do
    new(:bot, content)
  end

  def team(content) do
    new(:team, content)
  end

  def user(uid, content) do
    new({:user, uid}, content)
  end

  def user_id(msg = %__MODULE__{from: {:user, user_id}}), do: user_id

  defp new(from, content) do
    %__MODULE__{from: from, content: content, ts: DateTime.utc_now}
  end
end

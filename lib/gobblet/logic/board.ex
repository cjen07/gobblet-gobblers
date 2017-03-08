defmodule Gobblet.Logic.Board do
  defstruct data: [nil, nil, nil,
                   nil, nil, nil,
                   nil, nil, nil]

  @symbols [:x, :o]

  alias Gobblet.Logic

  def put(board, symbol, pos) when symbol in @symbols do
    case Enum.at(board.data, pos) do
      nil ->
        data = List.replace_at(board.data, pos, symbol)
        {:ok, %Logic.Board{board | data: data}}
      _ ->
        :error
    end
  end

  def put(_board, _symbol, _pos) do
    :error
  end

  def full?(%Logic.Board{data: data}) do
    Enum.all?(data, fn(val) -> val end)
  end

  def winner(%Logic.Board{data: data}) do
    do_winner(data)
  end

  defp do_winner([
    s, s, s,
    _, _, _,
    _, _, _
  ]) when s in @symbols, do: s

  defp do_winner([
    _, _, _,
    s, s, s,
    _, _, _
  ]) when s in @symbols, do: s

  defp do_winner([
    _, _, _,
    _, _, _,
    s, s, s
  ]) when s in @symbols, do: s

  defp do_winner([
    s, _, _,
    s, _, _,
    s, _, _
  ]) when s in @symbols, do: s

  defp do_winner([
    _, s, _,
    _, s, _,
    _, s, _
  ]) when s in @symbols, do: s

  defp do_winner([
    _, _, s,
    _, _, s,
    _, _, s
  ]) when s in @symbols, do: s

  defp do_winner([
    s, _, _,
    _, s, _,
    _, _, s
  ]) when s in @symbols, do: s

  defp do_winner([
    _, _, s,
    _, s, _,
    s, _, _
  ]) when s in @symbols, do: s

  defp do_winner(_), do: nil
end

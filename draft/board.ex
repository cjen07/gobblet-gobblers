defmodule Q do

@size 3
  @symbols [:x, :o]
  @init_data [[]] |> Stream.cycle |> Enum.take(@size * @size)
  @init_piece Enum.flat_map(@symbols, fn s -> 
    Enum.zip([Stream.cycle([s]),
              Stream.cycle([:a, :b]),
              1..@size 
              |> Enum.flat_map(fn(x) -> [x, x] end)])
  end)

  defstruct data: @init_data, pieces: @init_piece


  def drag_start(board, piece, pos) when piece in @init_piece do
    case pos do
      9 ->
        pieces = List.delete(board.pieces, piece)
        {:ok, %Q{board | pieces: pieces}}

      _ -> 
        stack = board.data |> Enum.at(pos) |> tl
        data = List.replace_at(board.data, pos, stack)
        case winner(data) do
          nil -> {:ok, %Q{board | data: data}}
          _ -> :error
        end
    end
  end

  def drag_end(board, piece1, pos1, pos2) when piece1 in @init_piece do
    stack = board.data |> Enum.at(pos2)
    piece2 = Enum.at(stack, 0)
    cond do
      pos1 == pos2 -> 
        data = List.replace_at(board.data, pos2, [piece1 | stack])
        {:back, %Q{board | data: data}}
        
      piece2 == nil or elem(piece2, 2) < elem(piece1, 2) -> 
        data = List.replace_at(board.data, pos2, [piece1 | stack])
        case winner(data) do
          nil -> {:ok, %Q{board | data: data}}
          symbol -> {:win, symbol}
        end

      true ->
        :error
    end
  end

  def winner(%Q{data: data}) do
    winner(data)
  end

  def winner(data) do
    do_winner(Enum.map(data, &(elem(Enum.at(&1, 0), 0))))
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

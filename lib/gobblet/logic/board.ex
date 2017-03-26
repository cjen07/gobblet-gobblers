defmodule Gobblet.Logic.Board do

  @size 3
  @symbols [:x, :o]
  @init_data [[]] |> Stream.cycle |> Enum.take(@size * @size)
  @init_piece Enum.flat_map(@symbols, fn s -> 
    Enum.zip([Stream.cycle([s]),
              Stream.cycle([:a, :b]),
              1..@size 
              |> Enum.flat_map(fn(x) -> [x, x] end)])
  end) |> Enum.map(&(Tuple.to_list(&1)))

  defstruct data: @init_data, pieces: @init_piece

  alias Gobblet.Logic

  def drag_start(board, piece, pos) when piece in @init_piece do
    case pos do
      9 ->
        pieces = List.delete(board.pieces, piece)
        {:ok, %Logic.Board{board | pieces: pieces}}

      _ -> 
        stack = board.data |> Enum.at(pos) |> tl
        data = List.replace_at(board.data, pos, stack)
        {:ok, %Logic.Board{board | data: data}}
    end
  end

  def drag_end(board, piece1, pos1, pos2) when piece1 in @init_piece do
    cond do
      pos1 == pos2 ->
        case pos2 do
          9 ->
            pieces = [piece1 | board.pieces]
            {:back, %Logic.Board{board | pieces: pieces}}
          _ ->
            stack = board.data |> Enum.at(pos2)
            data = List.replace_at(board.data, pos2, [piece1 | stack])
            {:back, %Logic.Board{board | data: data}}
        end

      true ->
        cond do
          pos2 == 9 ->
            {:error, "no moving back"}
          true ->
            stack = board.data |> Enum.at(pos2)
            piece2 = Enum.at(stack, 0)
            cond do
              piece2 == nil or Enum.at(piece2, 2) < Enum.at(piece1, 2) ->
                data = List.replace_at(board.data, pos2, [piece1 | stack])
                case winner(data) do
                  nil -> {:ok, %Logic.Board{board | data: data}}
                  :ok -> {:draw, %Logic.Board{board | data: data}}
                  symbol -> {:win, symbol, %Logic.Board{board | data: data}}
                end
              true ->
                # {:error, "need larger piece"}
                drag_end(board, piece1, pos1, pos1)
            end  
        end
    end
  end

  def winner(%Logic.Board{data: data}) do
    winner(data)
  end

  def winner(data) do
    data0 = 
      Enum.map(data, fn e -> 
        case Enum.at(e, 0) do
          nil -> nil
          l -> Enum.at(l, 0)
        end
      end)
    x_data = 
      Enum.map(data0, fn e ->
        case e do
          :x -> :x
          _  -> nil  
        end
      end)
    o_data = 
      Enum.map(data0, fn e ->
        case e do
          :o -> :o
          _  -> nil  
        end
      end)
    case {do_winner(x_data), do_winner(o_data)} do
      {nil, nil} -> nil
      {nil, :o}  -> :o
      {:x, nil}  -> :x
      _          -> :ok 
    end
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

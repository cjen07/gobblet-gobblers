defmodule QTest do
  use ExUnit.Case
  doctest Q
  import Q

  test "integration test 1" do

    # :x draw a piece from outside the board
    {msg0, board0} = drag_start(%Q{}, {:x, :a, 1}, 9)
    pieces0 = board0.pieces

    assert :ok == msg0
    assert false == Enum.any?(pieces0, &(&1 == {:x, :a, 1}))
    assert 11 == length(pieces0)

    # :x put an outside piece to the board
    {msg1, board1} = drag_end(board0, {:x, :a, 1}, 9, 2)
    data1 = board1.data
    pieces1 = board1.pieces

    assert :ok == msg1
    assert pieces1 == pieces0
    assert [{:x, :a, 1}] == Enum.at(data1, 2)

  end

  test "integration test 2" do

    # :o draw a piece from outside the board
    {:ok, board0} = drag_start(%Q{}, {:o, :a, 2}, 9)

    # :o put an outside piece back
    {msg1, board1} = drag_end(board0, {:o, :a, 2}, 9, 9)

    assert :back == msg1
    assert board1.data == board0.data
    assert board1.pieces == [{:o, :a, 2} | board0.pieces]
    assert 12 == length(board1.pieces)

  end

  test "integration test 3" do

    # :x draw a piece from outside the board
    {:ok, board0} = drag_start(%Q{}, {:x, :a, 1}, 9)

    # :x put an outside piece to the board
    {:ok, board1} = drag_end(board0, {:x, :a, 1}, 9, 2)

    # :x draw a piece from inside the board
    {:ok, board2} = drag_start(board1, {:x, :a, 1}, 2)

    assert [] == Enum.at(board2.data, 2)

    # :x put an inside piece back
    {msg3, board3} = drag_end(board2, {:x, :a, 1}, 2, 2)
    data3 = board3.data
    pieces3 = board3.pieces

    assert :back == msg3
    assert data3 == board1.data
    assert 11 == length(pieces3)

  end

  test "integration test 4" do

    # :x draw a piece from outside the board
    {:ok, board0} = drag_start(%Q{}, {:x, :a, 1}, 9)

    # :x put an outside piece to the board
    {:ok, board1} = drag_end(board0, {:x, :a, 1}, 9, 2)

    # :x draw a piece from inside the board
    {:ok, board2} = drag_start(board1, {:x, :a, 1}, 2)

    # :x put an inside piece to original pieces
    assert {:error, "no moving back"} = drag_end(board2, {:x, :a, 1}, 2, 9)

  end

  test "integration test 5" do

    # :x draw a piece from outside the board
    {:ok, board0} = drag_start(%Q{}, {:x, :a, 1}, 9)

    # :x put an outside piece to the board
    {:ok, board1} = drag_end(board0, {:x, :a, 1}, 9, 2)

    # :o draw a piece from outside the board
    {:ok, board2} = drag_start(board1, {:o, :a, 2}, 9)

    # :o put larger-size piece on top of a existed piece
    {msg3, board3} = drag_end(board2, {:o, :a, 2}, 9, 2)

    assert :ok == msg3
    assert [{:o, :a, 2}, {:x, :a, 1}] == Enum.at(board3.data, 2)
    assert board3.pieces == board2.pieces
    assert 10 == length(board3.pieces)

  end

  test "integration test 6" do

    # :x draw a piece from outside the board
    {:ok, board0} = drag_start(%Q{}, {:x, :a, 2}, 9)

    # :x put an outside piece to the board
    {:ok, board1} = drag_end(board0, {:x, :a, 2}, 9, 2)

    # :o draw a piece from outside the board
    {:ok, board2} = drag_start(board1, {:o, :a, 2}, 9)

    # :o put a no-larger-size piece on top of a existed piece
    assert {:error, "need larger piece"} == drag_end(board2, {:o, :a, 2}, 9, 2)

  end

  test "integration test 7" do

    # :x draw a piece from outside the board
    {:ok, board0} = drag_start(%Q{}, {:x, :a, 1}, 9)

    # :x put an outside piece to the board
    {:ok, board1} = drag_end(board0, {:x, :a, 1}, 9, 2)

    # :x draw a piece from outside the board
    {:ok, board2} = drag_start(board1, {:x, :b, 1}, 9)

    # :x put an outside piece to the board
    {:ok, board3} = drag_end(board2, {:x, :b, 1}, 9, 4)

    # :x draw a piece from outside the board
    {:ok, board4} = drag_start(board3, {:x, :b, 2}, 9)

    # :x put an outside piece to the board
    assert {:win, :x} = drag_end(board4, {:x, :b, 2}, 9, 6)

  end

  test "integration test 8" do

    # :x draw a piece from outside the board
    {:ok, board0} = drag_start(%Q{}, {:x, :a, 1}, 9)

    # :x put an outside piece to the board
    {:ok, board1} = drag_end(board0, {:x, :a, 1}, 9, 2)

    # :x draw a piece from outside the board
    {:ok, board2} = drag_start(board1, {:x, :b, 1}, 9)

    # :x put an outside piece to the board
    {:ok, board3} = drag_end(board2, {:x, :b, 1}, 9, 4)

    # :o draw a piece from outside the board
    {:ok, board4} = drag_start(board3, {:o, :b, 3}, 9)

    # :o put an outside piece to the board
    {:ok, board5} = drag_end(board4, {:o, :b, 3}, 9, 4)

    # :x draw a piece from outside the board
    {:ok, board6} = drag_start(board5, {:x, :b, 2}, 9)

    # :x put an outside piece to the board
    {:ok, board7} = drag_end(board6, {:x, :b, 2}, 9, 6)

    # :o draw a piece from inside the board
    assert {:error, "your will lose"} == drag_start(board7, {:o, :b, 3}, 4)

  end
end

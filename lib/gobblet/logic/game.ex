defmodule Gobblet.Logic.Game do
  use GenServer

  alias Gobblet.Logic

  @initial_score %{x: 0, ties: 0, o: 0}

  defstruct(
    board: %Logic.Board{},
    x: nil,
    o: nil,
    first: :x,
    next: :x,
    score: @initial_score,
    finished: false
  )

  def start_link(name) do
    GenServer.start_link(__MODULE__, nil, name: via_tuple(name))
  end

  def join(game, player) do
    GenServer.call(game, {:join, player})
  end

  def leave(game, symbol) do
    GenServer.call(game, {:leave, symbol})
  end

  def drag_start(game, piece, pos) do
    GenServer.call(game, {:drag_start, piece, pos})
  end

  def drag_end(game, piece, pos1, pos2) do
    GenServer.call(game, {:drag_end, piece, pos1, pos2})
  end

  # def put(game, symbol, pos) do
  #   GenServer.call(game, {:put, symbol, pos})
  # end

  def new_round(game) do
    GenServer.call(game, :new_round)
  end

  def whereis(name) do
    Registry.lookup(Registry.Gobblet, name)
  end

  defp via_tuple(name) do
    {:via, Registry, {Registry.Gobblet, name}}
  end

  def init(_) do
    {:ok, %Logic.Game{}}
  end

  def handle_call(:new_round, _from, state) do
    new_state =
      %{state | board: %Logic.Board{}, finished: false}
      |> next_round()
    {:reply, new_state, new_state}
  end

  def handle_call({:join, player}, _form, %{x: nil} = state) do
    new_state = %{state | x: player, finished: false}
    {:reply, {:ok, :x, new_state}, new_state}
  end

  def handle_call({:join, player}, _form, %{o: nil} = state) do
    new_state = %{state | o: player, finished: false}
    {:reply, {:ok, :o, new_state}, new_state}
  end

  def handle_call({:join, _player}, _from, state) do
    {:reply, :error, state}
  end

  def handle_call({:leave, symbol}, _from, state) do
    new_state =
      state
      |> remove_player(symbol)
      |> reset_score()
      |> reset_board()

    if empty?(new_state) do
      {:stop, :normal, new_state, new_state}
    else
      {:reply, new_state, new_state}
    end
  end

  def handle_call({:drag_start, _piece, _pos}, _from, %{finished: true} = state) do
    {:reply, :finished, state}
  end

  def handle_call({:drag_start, {symbol, _, _} = piece, pos}, _from, %{next: symbol} = state) do
    case Logic.Board.drag_start(state.board, piece, pos) do
      {:ok, board} ->
        new_state = %{state | board: board}
        {:reply, {:ok, new_state}, new_state}

      {:error, reason} ->
        {:reply, {:retry, reason}, state}
    end
  end

  def handle_call({:drag_start, _piece, _pos}, _form, state) do
    {:reply, :cheat, state}
  end

  def handle_call({:drag_end, _piece, _pos1, _pos2}, _from, %{finished: true} = state) do
    {:reply, :finished, state}
  end

  def handle_call({:drag_end, {symbol, _, _} = piece, pos1, pos2}, _from, %{next: symbol} = state) do
    case Logic.Board.drag_end(state.board, piece, pos1, pos2) do
      {:ok, board} ->
        state = %{state | board: board}
        new_state = next_turn(state)
        {:reply, {:ok, new_state}, new_state}

      {:back, board} ->
        new_state = %{state | board: board}
        {:reply, {:ok, new_state}, new_state}

      {:win, winner} ->
        state = %{state | board: board}
        new_state = finish_game(state, winner)
        {:reply, {:winner, winner, new_state}, new_state}

      {:error, reason} ->
        {:reply, {:retry, reason}, state}
    end
  end

  def handle_call({:drag_end, _piece, _pos1, _pos2}, _form, state) do
    {:reply, :cheat, state}
  end

  defp finish_game(state, symbol) do
    score = Map.update!(state.score, symbol, &(&1 + 1))
    %{state | score: score, finished: true}
  end

  defp next_turn(%{next: :x} = state) do
    %{state | next: :o}
  end

  defp next_turn(%{next: :o} = state) do
    %{state | next: :x}
  end

  defp next_round(%{first: :x} = state) do
    %{state | first: :o, next: :o}
  end

  defp next_round(%{first: :o} = state) do
    %{state | first: :x, next: :x}
  end

  defp empty?(%{x: nil, o: nil}) do
    true
  end

  defp empty?(%{x: _, o: _}) do
    false
  end

  defp remove_player(state, symbol) do
    Map.put(state, symbol, nil)
  end

  defp reset_score(state) do
    %{state | score: @initial_score}
  end

  defp reset_board(state) do
    %{state | board: %Logic.Board{}}
  end
end

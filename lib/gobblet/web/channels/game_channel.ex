defmodule Gobblet.Web.GameChannel do
  use Phoenix.Channel

  alias Gobblet.Logic

  require Logger

  def join("game:" <> name, _params, socket) do
    game = Logic.GameSupervisor.game_process(name)
    case Logic.Game.join(game, socket.assigns.player) do
      {:ok, symbol, game_state} ->
        send self(), {:after_join, game_state}
        socket =
          socket
          |> assign(:game, name)
          |> assign(:symbol, symbol)
        {:ok, symbol, socket}
      :error ->
        {:error, %{reason: "full game"}}
    end
  end

  def handle_in("drag_start", %{"piece" => piece, "pos" => pos}, socket) do
    piece = [String.to_atom(piece["0"]), String.to_atom(piece["1"]), piece["2"]]
    game = Logic.GameSupervisor.game_process(socket.assigns.game)
    if socket.assigns.symbol == Enum.at(piece, 0) do
      case Logic.Game.drag_start(game, piece, pos) do
        {:ok, game_state} ->
          broadcast! socket, "update_board", game_state
        _ ->
          :ok
      end
    end
    {:noreply, socket}
  end

  def handle_in("drag_end", %{"piece" => piece, "pos1" => pos1, "pos2" => pos2}, socket) do
    piece = [String.to_atom(piece["0"]), String.to_atom(piece["1"]), piece["2"]]
    game = Logic.GameSupervisor.game_process(socket.assigns.game)
    if socket.assigns.symbol == Enum.at(piece, 0) do
      case Logic.Game.drag_end(game, piece, pos1, pos2) do
        {:ok, game_state} ->
          broadcast! socket, "update_board", game_state
        {:back, game_state} ->
          broadcast! socket, "update_board", game_state
        {:draw, game_state} ->
          broadcast! socket, "finish_game", game_state
        {:winner, _symbol, game_state} ->
          broadcast! socket, "finish_game", game_state
        _ ->
          :ok
      end
    end
    {:noreply, socket}
  end

  def handle_in("new_round", _params, socket) do
    game = Logic.GameSupervisor.game_process(socket.assigns.game)
    game_state = Logic.Game.new_round(game)
    broadcast! socket, "new_round", game_state
    {:noreply, socket}
  end

  def handle_in("concede", %{"symbol" => symbol}, socket) do
    game = Logic.GameSupervisor.game_process(socket.assigns.game)
    {:winner, _symbol, game_state} = Logic.Game.concede(game, String.to_atom(symbol))
    broadcast! socket, "finish_game", game_state
    {:noreply, socket}
  end

  def handle_info({:after_join, game_state}, socket) do
    broadcast! socket, "new_player", game_state
    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    game = Logic.GameSupervisor.game_process(socket.assigns.game)
    Logic.Game.leave(game, socket.assigns.symbol)
    broadcast! socket, "player_left", %{}
  end
end

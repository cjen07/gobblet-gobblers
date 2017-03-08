import "phoenix_html"
import {Socket} from "phoenix"
import Game from "./game"

let socket = new Socket(
  "/socket",
  {params: {player: window.currentPlayer}}
)

let element = document.getElementById("game")
if (element) {
  Game.init(socket)
}

let elmDiv = document.getElementById('elm-player-new')
if (elmDiv) {
  let csrf = elmDiv.getAttribute("csrf")
  Elm.Main.embed(elmDiv, {csrf: csrf})
}

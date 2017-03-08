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

let elmDiv = document.getElementById('elm-main')
if (elmDiv) {
  let view = elmDiv.getAttribute("view")
  let msg = elmDiv.getAttribute("msg")
  Elm.Main.embed(elmDiv, {view: view, msg: msg})
}

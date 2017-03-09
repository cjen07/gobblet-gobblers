import "phoenix_html"

let elmDiv = document.getElementById('elm-main')
if (elmDiv) {
  let view = elmDiv.getAttribute("view")
  let msg = elmDiv.getAttribute("msg")
  Elm.Main.embed(elmDiv, 
    {view: view, msg: msg, player: window.currentPlayer})
}

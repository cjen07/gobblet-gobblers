let Game = {
  stats: document.getElementById("stats"),
  waiting: document.getElementById("waiting"),
  newGame: document.getElementById("new_game"),
  game: document.getElementById("game"),
  fullGame: document.getElementById("full_game"),
  xName: document.getElementById("x_name"),
  oName: document.getElementById("o_name"),
  xScore: document.getElementById("x_score"),
  tiesScore: document.getElementById("ties_score"),
  oScore: document.getElementById("o_score"),
  xTurn: document.getElementById("x_turn"),
  oTurn: document.getElementById("o_turn"),

  init(socket) {
    socket.connect()

    let gameName = game.getAttribute("data-name")
    let gameChannel = socket.channel("game:" + gameName)

    gameChannel.params.player = window.currentPlayer

    gameChannel.join()
      .receive("ok", resp => {
        // noop
      })
      .receive("error", (reason) => {
        this.show(this.fullGame)
      })

    gameChannel.on("new_player", (resp) => {
      if (resp.x && resp.o) {
        this.updateBoard(resp)
        this.updateStats(resp)
        this.hide(this.waiting)
        this.hide(this.newGame)
        this.show(this.game)
        this.show(this.stats)
      } else {
        this.show(this.waiting)
      }
    })

    gameChannel.on("player_left", (resp) => {
      this.hide(this.stats)
      this.hide(this.game)
      this.hide(this.newGame)
      this.show(this.waiting)
    })

    gameChannel.on("update_board", (resp) => {
      this.updateBoard(resp)
    })

    gameChannel.on("new_round", (resp) => {
      this.hide(this.newGame)
      this.updateBoard(resp)
    })

    gameChannel.on("finish_game", (resp) => {
      this.updateBoard(resp)
      this.updateStats(resp)
      this.show(this.newGame)
    })

    game.addEventListener("click", (e) => {
      e.preventDefault()
      let index = e.target.getAttribute("data-index")
      gameChannel.push("put", {index: index})
    })

    this.newGame.addEventListener("click", (e) => {
      e.preventDefault()
      gameChannel.push("new_round")
    })
  },

  show(element) {
    element.classList.remove("hidden")
  },

  hide(element) {
    element.classList.add("hidden")
  },

  updateBoard(resp) {
    let data = resp.board.data
    for (let i = 0; i < data.length; i++) {
      document.getElementById("index_" + i).innerHTML = data[i]
    }
    this.showNext(resp.next)
  },

  updateStats(game) {
    this.xName.innerHTML = game.x
    this.oName.innerHTML = game.o
    this.xScore.innerHTML = game.score.x
    this.tiesScore.innerHTML = game.score.ties
    this.oScore.innerHTML = game.score.o
  },

  showNext(symbol) {
    if (symbol == "x") {
      this.hide(this.oTurn)
      this.show(this.xTurn)
    } else {
      this.hide(this.xTurn)
      this.show(this.oTurn)
    }
  }
}

export default Game

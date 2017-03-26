## gobblet gobblers
gobblet gobblers game in elixir, phoenix and elm

Play online: [playground](https://immense-fjord-94074.herokuapp.com/)

Rules: [gobblet-gobblers](https://github.com/cjen07/gobblet-gobblers/blob/master/rules/gobblet%20gobblers%20rules.pdf)

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.create && mix ecto.migrate`
  * Install Node.js dependencies with `cd assets && npm install`
  * Install Elm dependencies with `cd assets/elm && `[`elm_install`](https://github.com/gdotdesign/elm-github-install)
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### to-do
- [x] use phoenix v1.3
- [x] replace js by elm
- [x] add gobblet logic
- [x] add gobblet view
- [x] test and publish

### to-do for user experience
- [ ] show info when you pick up a piece
- [ ] need way to notify error not omit it
- [ ] add unique id support like email
- [ ] show hidden piece with no memory needed
- [ ] better ui design with color and animation

### to-do for special rules
- [ ] after a player moves a piece, if both players have 3 pieces in a line, the game ties

### remark
* this repo is highly encouraged by this [repo](https://github.com/ventsislaf/talks).
* I fixed two bugs and updated for elixir v1.4 using Registry: [repo](https://github.com/cjen07/from_tictactoe_to_gobblet).

module Main exposing (..)

import Phoenix
import Phoenix.Socket as Socket exposing (Socket)
import Phoenix.Channel as Channel exposing (Channel)
import Phoenix.Push as Push

import Json.Encode as JE
import Json.Decode as JD exposing (Decoder)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)

import Array exposing (Array, repeat, get)



main : Program Flags Model Msg
main = 
  programWithFlags 
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }



-- MODEL


type alias Flags = 
  { view : String
  , msg : String
  , player: String
  }


type alias Visible =
  { full : Bool
  , game : Bool
  , newgame : Bool
  }


type alias Stats =
  { xName : String
  , oName : String
  , xScore : Int
  , tiesScore : Int
  , oScore : Int
  }


type alias Board =
  { pieces: Array (Maybe String)
  , next: String
  }


type alias Model =
  { visible : Visible
  , flags : Flags 
  , stats : Stats
  , board : Board
  }


init : Flags -> (Model, Cmd Msg)
init flags =
  let
    visible = 
      Visible True True True
    stats = 
      Stats "" "" 0 0 0
    board = 
      Board (repeat 9 Nothing) "x"
  in 
  (Model visible flags stats board, Cmd.none)



-- UPDATE


type Msg 
  = OnJoinOk
  | OnJoinError
  | NewGame
  | PutPiece String
  | NewPlayer JD.Value
  | PlayerLeft JD.Value
  | UpdateBoard JD.Value
  | NewRound JD.Value
  | FinishGame JD.Value


decodeBoard : Decoder Board
decodeBoard = 
  JD.map2 Board
    (JD.at [ "board","data" ] (JD.array <| JD.nullable <| JD.string))
    (JD.field "next" JD.string)


updateBoard : JD.Value -> Maybe Board
updateBoard resp =
  case JD.decodeValue decodeBoard resp of
    Ok board -> Just board
    Err _ -> Nothing


decodeStats : Decoder Stats
decodeStats = 
  JD.map5 Stats
    (JD.field "x" JD.string)
    (JD.field "o" JD.string)
    (JD.at [ "score","x" ] JD.int)
    (JD.at [ "score","ties" ] JD.int)
    (JD.at [ "score","o" ] JD.int)


updateStats : JD.Value -> Maybe Stats
updateStats resp =
  case JD.decodeValue decodeStats resp of
    Ok stats -> Just stats
    Err _ -> Nothing


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  let
    { visible, flags, stats, board } = model
  in
    case msg of
      OnJoinOk ->
        model ! []
      OnJoinError ->
        { model | visible = { visible | full = False } } ! []
      NewGame ->
        let
          push = 
            Push.init ("game:" ++ model.flags.msg) "new_round"
        in
          model ! [ Phoenix.push echoServer push ]
      PutPiece piece ->
        let
          push = 
            Push.init ("game:" ++ model.flags.msg) "put"
              |> Push.withPayload (JE.object [ ("index", JE.string piece) ])
        in
          model ! [ Phoenix.push echoServer push ]
      NewPlayer resp ->
        case (updateBoard resp, updateStats resp) of
          (Just board, Just stats) ->
            { model | visible = { visible | newgame = True, game = False }, board = board, stats = stats } ! []
          _ ->
            { model | visible = { visible | game = True } } ! []
      PlayerLeft _ ->
        { model | visible = { visible | newgame = True, game = True } } ! []
      UpdateBoard resp ->
        case updateBoard resp of
          Just board ->
            { model | board = board } ! []
          _ ->
            model ! []
      NewRound resp ->
        case updateBoard resp of
          Just board ->
            { model | visible = { visible | newgame = True }, board = board } ! []
          _ ->
            model ! []
      FinishGame resp ->
        case (updateBoard resp, updateStats resp) of
          (Just board, Just stats) ->
            { model | visible = { visible | newgame = False }, board = board, stats = stats } ! []
          _ ->
            model ! []



-- SUBSCRIPTIONS


echoServer : String
echoServer =
    "ws://localhost:4000/socket/websocket"


socket : String -> Socket Msg
socket player =
  Socket.init echoServer
    |> Socket.withParams [ ("player", player) ]
      


channel : String -> Channel Msg
channel gameName = 
  Channel.init ("game:" ++ gameName)
    |> Channel.onJoin (\_ -> OnJoinOk)
    |> Channel.onJoinError (\_ -> OnJoinError)
    |> Channel.on "new_player" NewPlayer
    |> Channel.on "player_left" PlayerLeft
    |> Channel.on "update_board" UpdateBoard
    |> Channel.on "new_round" NewRound
    |> Channel.on "finish_game" FinishGame
    |> Channel.withDebug


subscriptions : Model -> Sub Msg
subscriptions model =
  let
    flags = model.flags
  in
    case flags.view of
      "game_show" -> 
        Phoenix.connect (socket flags.player) [ channel flags.msg ]
      _ -> 
        Sub.none
  


-- VIEW


view : Model -> Html Msg
view model =
  let
    flags = model.flags
  in
    case flags.view of
      "game_show" -> boardView model
      _ -> formView flags


pieceView : Int -> Array (Maybe String) -> Html Msg
pieceView num pieces =
  case get num pieces of
    Just (Just value) -> text value
    _ -> text ""


boardView : Model -> Html Msg
boardView model = 
  let
    { visible, flags, stats, board } = model
    { pieces, next } = board
  in
  div [] 
    [ div 
      [ id "full", classList [ ("msg", True), ("hidden", visible.full) ] ] 
      [ text "Sorry, the game is already full :(" ]
    , div 
      [ id "waiting", classList [ ("msg", True), ("hidden", not visible.game) ] ] 
      [ text "Waiting for a second player..." ]
    , table 
      [ id "game", attribute "data-name" flags.msg, classList [ ("hidden", visible.game) ] ]
      [ tr [ class "top" ]
        [ td [ id "index_0", class "left", onClick (PutPiece "0") ] [ pieceView 0 pieces ]
        , td [ id "index_1", onClick (PutPiece "1") ] [ pieceView 1 pieces ]
        , td [ id "index_2", class "right", onClick (PutPiece "2") ] [ pieceView 2 pieces ]
        ]
      , tr []
        [ td [ id "index_3", class "left", onClick (PutPiece "3") ] [ pieceView 3 pieces ]
        , td [ id "index_4", onClick (PutPiece "4") ] [ pieceView 4 pieces ]
        , td [ id "index_5", class "right", onClick (PutPiece "5") ] [ pieceView 5 pieces ]
        ]
      , tr [ class "bottom" ]
        [ td [ id "index_6", class "left", onClick (PutPiece "6") ] [ pieceView 6 pieces ]
        , td [ id "index_7", onClick (PutPiece "7") ] [ pieceView 7 pieces ]
        , td [ id "index_8", class "right", onClick (PutPiece "8") ] [ pieceView 8 pieces ]
        ]
      ]
    , div 
      [ id "stats", classList [ ("hidden", visible.game) ] ]
      [ div 
        [ id "x", class "block" ]
        [ div 
          [ class "name" ]
          [ span
            [ id "x_turn", classList [ ("turn", True), ("hidden", next /= "x") ] ]
            [ text "⇨" ]
          , span [ id "x_name" ] [ text stats.xName ]
          , span [] [ text "(x)" ]
          ]
        , div [ id "x_score", class "score" ] [ text <| toString <| stats.xScore ]
        ]
      , div 
        [ id "ties", class "block" ] 
        [ div [ class "name" ] [ text "ties" ]
        , div [ id "ties_score", class "score" ] [ text <| toString <| stats.tiesScore ]
        ]
      , div 
        [ id "o", class "block" ]
        [ div 
          [ class "name" ]
          [ span [ id "o_name" ] [ text stats.oName ]
          , span [] [ text "(o)" ]
          , span
            [ id "o_turn", classList [ ("turn", True), ("hidden", next /= "o") ] ]
            [ text "⇦" ]
          ]
        , div [ id "o_score", class "score" ] [ text <| toString <| stats.oScore ]
        ]
      ]
    , div 
      [ class "text-center" ] 
      [ button 
        [ id "new_game"
        , classList 
          [ ("btn btn-primary", True)
          , ("hidden", visible.newgame)
          ]
        , onClick NewGame 
        ]
        [ text "NEW GAME" ] 
      ]
    ]


formView : Flags -> Html Msg
formView flags =
  let
    word = String.dropRight 4 flags.view
    str1 = "/" ++ word ++ "s"
    str2 = word ++ "_name"
    str3 = word ++ "[name]"
    (str4, str5) = 
      case word of
        "player" -> ("Enter your name", "Enter")
        _ -> ("Enter a game name", "Play")
  in 
    div [ class "form" ]
      [ Html.form 
        [ acceptCharset "UTF-8"
        , action str1
        , method "post" 
        ] 
        [ input 
          [ name "_csrf_token"
          , type_ "hidden"
          , value flags.msg ] []
        , div [ class "input-group" ]
          [ input 
            [ autofocus True
            , class "form-control"
            , id str2
            , name str3
            , placeholder str4
            , type_ "text"
            ] []
          , span
            [ class "input-group-btn" ] 
            [ button 
              [ class "btn btn-primary"
              , type_ "submit"
              ] 
              [ text str5 ]
            ]
          ]
        ]
      ]
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

import Debug exposing (log)



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


type alias Piece =
  { symbol : String
  , mark : String
  , size : Int
  }


type alias Board =
  { data: Array (List Piece)
  , pieces: Array Piece
  , next: String
  }

type alias DragState =
  { start : Bool
  , piece : Piece
  , pos : Int
  }


type alias Model =
  { visible : Visible
  , flags : Flags 
  , stats : Stats
  , board : Board
  , dragState : DragState
  }


init : Flags -> (Model, Cmd Msg)
init flags =
  let
    visible = 
      Visible True True True
    stats = 
      Stats "" "" 0 0 0
    board = 
      Board 
      (repeat 9 [ Piece "" "" 0 ])
      (repeat 12 (Piece "" "" 0))
      "x"
    dragState =
      DragState False (Piece "" "" 0) 0
  in 
    (Model visible (log "flags" flags) stats board dragState, Cmd.none)



-- UPDATE


type Msg 
  = None
  | OnJoinOk
  | OnJoinError
  | NewGame
  | DragMsg Piece Int
  | NewPlayer JD.Value
  | PlayerLeft JD.Value
  | UpdateBoard JD.Value
  | NewRound JD.Value
  | FinishGame JD.Value


decodePiece : Decoder Piece
decodePiece = 
  JD.map3 Piece
    (JD.field "0" JD.string)
    (JD.field "1" JD.string)
    (JD.field "2" JD.int)


encodePiece : Piece -> JE.Value
encodePiece piece =
  let
    { symbol, mark, size } = piece
  in
    JE.object
      [ ("0", JE.string symbol)
      , ("1", JE.string mark)
      , ("2", JE.int size)
      ]


decodeBoard : Decoder Board
decodeBoard = 
  JD.map3 Board
    (JD.at [ "board","data" ] (JD.array <| JD.list <| decodePiece))
    (JD.at [ "board","pieces" ] (JD.array decodePiece))
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
    { visible, flags, stats, board, dragState } = model
  in
    case log "msg" msg of
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
      DragMsg piece pos ->
        let
          (push, newDragState) =
            case dragState.start of
              False ->
                (Push.init ("game:" ++ model.flags.msg) "drag_start"
                  |> Push.withPayload (JE.object [ ("piece", encodePiece piece)
                                                 , ("pos", JE.int pos) 
                                                 ])
                , DragState True piece pos)
              True ->
                (Push.init ("game:" ++ model.flags.msg) "drag_end"
                  |> Push.withPayload (JE.object [ ("piece", encodePiece dragState.piece)
                                                 , ("pos1", JE.int dragState.pos)
                                                 , ("pos2", JE.int pos)
                                                 ])
                , DragState False (Piece "" "" 0) 0)
        in
          { model | dragState = newDragState } ! [ Phoenix.push echoServer push ]
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
      None ->
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


dataView : Int -> Array (List Piece) -> Html Msg
dataView num data =
  case get num data of
    Just data1 -> 
      case List.head data1 of
        Just piece ->
          text (toString(piece.size) ++ piece.symbol)
        _ ->
          text ""
    _ -> 
      text ""


pickPieces : String -> (Int, Piece) -> Bool
pickPieces symbol int_piece =
  symbol == (Tuple.second int_piece).symbol


showPiece : Int -> Int -> Int -> (Int, Piece) -> Html Msg
showPiece first last index int_piece =
  let
    (pos, piece) = int_piece
  in
    td
      [ classList [ ("left", index == first), ("right", index == last) ] ]
      [ text (toString(piece.size) ++ piece.symbol) ]


showPieces : Array (Int, Piece) -> List (Html Msg)
showPieces pieces =
  let
    first = 0
    last = (Array.length pieces) - 1
  in
    Array.toList <| Array.indexedMap (showPiece first last) pieces


piecesView : String-> Array Piece -> Html Msg
piecesView symbol pieces =
  let
    my_pieces = Array.fromList <| List.filter (pickPieces symbol) (Array.toIndexedList pieces)
  in
    table
      [ id (symbol ++ "pieces"), class "pieces" ]
      [ tr [ classList [ ("top", True), ("bottom", True) ] ]
        (showPieces my_pieces)
      ]


dragEvent : Int -> Array (List Piece) -> Msg
dragEvent num data =
  case get num data of
    Just data1 -> 
      case List.head data1 of
        Just piece ->
          DragMsg piece num
        _ ->
          None
    _ -> 
      None


boardView : Model -> Html Msg
boardView model = 
  let
    { visible, flags, stats, board, dragState } = model
    { data, pieces, next } = board
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
        [ td [ id "index_0", class "left", onClick (dragEvent 0 data) ] [ dataView 0 data ]
        , td [ id "index_1", onClick (dragEvent 1 data) ] [ dataView 1 data ]
        , td [ id "index_2", class "right", onClick (dragEvent 2 data) ] [ dataView 2 data ]
        ]
      , tr []
        [ td [ id "index_3", class "left", onClick (dragEvent 3 data) ] [ dataView 3 data ]
        , td [ id "index_4", onClick (dragEvent 4 data) ] [ dataView 4 data ]
        , td [ id "index_5", class "right", onClick (dragEvent 5 data) ] [ dataView 5 data ]
        ]
      , tr [ class "bottom" ]
        [ td [ id "index_6", class "left", onClick (dragEvent 6 data) ] [ dataView 6 data ]
        , td [ id "index_7", onClick (dragEvent 7 data) ] [ dataView 7 data ]
        , td [ id "index_8", class "right", onClick (dragEvent 8 data) ] [ dataView 8 data ]
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
        , (piecesView "x" pieces)
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
        , (piecesView "o" pieces)
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
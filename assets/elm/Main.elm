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

import Svg exposing (svg, circle)
import Svg.Attributes as SA

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
  , self : String 
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
    (Model visible flags "" stats board dragState, Cmd.none)



-- UPDATE


type Msg 
  = None
  | OnJoinOk JD.Value
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
    { visible, flags, self, stats, board, dragState } = model
  in
    case log "msg" msg of
      OnJoinOk resp ->
        let
          newSelf = 
            case JD.decodeValue JD.string resp of
              Ok symbol -> symbol
              Err _ -> ""
        in
          { model | self = newSelf } ! []
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
            case dragState.piece.symbol == board.next of
              True ->
                { model | board = board } ! []
              False ->
                { model | board = board, dragState = (DragState False (Piece "" "" 0) 0) } ! []            
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
    |> Channel.onJoin OnJoinOk
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
          drawPiece "large" piece
        _ ->
          text ""
    _ -> 
      text ""


drawPiece : String -> Piece -> Html Msg
drawPiece size piece =
  let
    r0 =
      case size of
        "small" -> 20
        _ -> 60
    r1 = 
      case piece.size of
        1 -> r0 / 2
        2 -> r0 / 3 * 2.2
        _ -> r0
    color =
      case piece.symbol of
        "x" -> "blue"
        _ -> "orange"
    edge = toString (2 * r0 + 10)
    viewbox = "0 0 " ++ edge ++ " " ++ edge
    s0 = toString (r0 + 5)
    s1 = toString r1 
  in
    svg
      [ SA.width edge, SA.height edge, SA.viewBox viewbox ]
      [ circle [ SA.cx s0, SA.cy s0, SA.r s1, SA.fill color ] [] ]


pickPieces : String -> (Int, Piece) -> Bool
pickPieces symbol int_piece =
  symbol == (Tuple.second int_piece).symbol


pickEvent : Bool -> Piece -> Msg
pickEvent my_turn piece = 
  case my_turn of
    True -> DragMsg piece 9
    False -> None


showPiece : Bool -> Int -> (Int, Piece) -> Html Msg
showPiece my_turn index int_piece =
  let
    (pos, piece) = int_piece
  in
    td
      [ classList [ ("no_border", True) ], onClick (pickEvent my_turn piece) ]
      [ drawPiece "small" piece ]


showPieces : Bool -> Array (Int, Piece) -> List (Html Msg)
showPieces my_turn pieces =
  Array.toList <| Array.indexedMap (showPiece my_turn) pieces


piecesView : String -> Bool -> Array Piece -> Html Msg
piecesView symbol my_turn pieces =
  let
    my_pieces = Array.fromList <| List.filter (pickPieces symbol) (Array.toIndexedList pieces)
  in
    table
      [ id (symbol ++ "pieces"), class "pieces" ]
      [ tr [ classList [ ("top", True), ("bottom", True) ] ]
        (showPieces my_turn my_pieces)
      ]


dragEvent : Bool -> Bool -> String -> Int -> Array (List Piece) -> Msg
dragEvent my_turn start self num data =
  case my_turn of
    False -> None
    True ->
      case get num data of
        Nothing -> None
        Just data1 -> 
          case List.head data1 of
            Nothing ->
              case start of
                True -> DragMsg (Piece "" "" 0) num
                False -> None
            Just piece ->
              case start of
                True -> DragMsg piece num
                False ->     
                  case piece.symbol == self of
                    True -> DragMsg piece num
                    False -> None


infoView : DragState -> Html Msg
infoView dragState =
  case dragState.start of
    False -> text ""
    True ->
      let
        size = 
          case dragState.piece.size of
            1 -> "small"
            2 -> "middle"
            _ -> "large"
      in
        text ("You have picked up a " ++ size ++ "-size piece.")

boardView : Model -> Html Msg
boardView model = 
  let
    { visible, flags, self, stats, board, dragState } = model
    { data, pieces, next } = board
    start = dragState.start
    my_turn = self == next
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
        [ td [ id "index_0", class "left", onClick (dragEvent my_turn start self 0 data) ] [ dataView 0 data ]
        , td [ id "index_1", onClick (dragEvent my_turn start self 1 data) ] [ dataView 1 data ]
        , td [ id "index_2", class "right", onClick (dragEvent my_turn start self 2 data) ] [ dataView 2 data ]
        ]
      , tr []
        [ td [ id "index_3", class "left", onClick (dragEvent my_turn start self 3 data) ] [ dataView 3 data ]
        , td [ id "index_4", onClick (dragEvent my_turn start self 4 data) ] [ dataView 4 data ]
        , td [ id "index_5", class "right", onClick (dragEvent my_turn start self 5 data) ] [ dataView 5 data ]
        ]
      , tr [ class "bottom" ]
        [ td [ id "index_6", class "left", onClick (dragEvent my_turn start self 6 data) ] [ dataView 6 data ]
        , td [ id "index_7", onClick (dragEvent my_turn start self 7 data) ] [ dataView 7 data ]
        , td [ id "index_8", class "right", onClick (dragEvent my_turn start self 8 data) ] [ dataView 8 data ]
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
          ]
        , div [ id "x_score", class "score" ] [ text <| toString <| stats.xScore ]
        , (piecesView "x" (next == "x" && self == "x") pieces)
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
          , span
            [ id "o_turn", classList [ ("turn", True), ("hidden", next /= "o") ] ]
            [ text "⇦" ]
          ]
        , div [ id "o_score", class "score" ] [ text <| toString <| stats.oScore ]
        , (piecesView "o" (next == "o" && self == "o") pieces)
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
    , div 
      [ class "text-center" ] 
      [ h3 
        [ id "game_info"
        , classList 
          [ ("hidden", not start)
          ] 
        ]
        [ infoView dragState ] 
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
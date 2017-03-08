module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)

type alias Model =
  { view : String
  , msg : String
  }

main : Program Model Model Never
main = 
  programWithFlags 
    { init = \ model -> ( model, Cmd.none )
    , subscriptions = \ _ -> Sub.none
    , update = \ _ -> \ model -> ( model, Cmd.none )
    , view = view
    }


view : Model -> Html Never
view model =
  case model.view of
    "game_show" -> boardView model
    _ -> formView model


boardView : Model -> Html Never
boardView model = 
  div [] 
    [ div 
      [ id "full_game", class "msg hidden" ] 
      [ text "Sorry, the game is already full :(" ]
    , div 
      [ id "waiting", class "msg hidden" ] 
      [ text "Waiting for a second player..." ]
    , table 
      [ id "game", attribute "data-name" model.msg, class "hidden" ]
      [ tr [ class "top" ]
        [ td [ id "index_0", class "left", attribute "data-index" "0" ] []
        , td [ id "index_1", attribute "data-index" "1" ] []
        , td [ id "index_2", class "right", attribute "data-index" "2" ] []
        ]
      , tr []
        [ td [ id "index_3", class "left", attribute "data-index" "3" ] []
        , td [ id "index_4", attribute "data-index" "4" ] []
        , td [ id "index_5", class "right", attribute "data-index" "5" ] []
        ]
      , tr [ class "bottom" ]
        [ td [ id "index_6", class "left", attribute "data-index" "6" ] []
        , td [ id "index_7", attribute "data-index" "7" ] []
        , td [ id "index_8", class "right", attribute "data-index" "8" ] []
        ]
      ]
    , div 
      [ id "stats", class "hidden" ]
      [ div 
        [ id "x", class "block" ]
        [ div 
          [ class "name" ]
          [ span
            [ id "x_turn", class "turn" ]
            [ text "&#8680;" ]
          , span [ id "x_name" ] []
          , span [] [ text "(x)" ]
          ]
        , div [ id "x_score", class "score" ] []
        ]
      , div 
        [ id "ties", class "block" ] 
        [ div [ class "name" ] [ text "ties" ]
        , div [ id "ties_score", class "score" ] []
        ]
      , div 
        [ id "o", class "block" ]
        [ div 
          [ class "name" ]
          [ span [ id "o_name" ] []
          , span [] [ text "(o)" ]
          , span
            [ id "o_turn", class "turn" ]
            [ text "&#8678;" ]
          ]
        , div [ id "o_score", class "score" ] []
        ]
      ]
    , div 
      [ class "text-center" ] 
      [ button 
        [ id "new_game", class "btn btn-primary hidden" ]
        [ text "NEW GAME" ] 
      ]
    ]


formView : Model -> Html Never
formView model =
  let
    word = String.dropRight 4 model.view
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
          , value model.msg ] []
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
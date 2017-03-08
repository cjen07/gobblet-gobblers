module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


main : Program Model Model Never
main = 
  programWithFlags 
    { init = \ model -> ( model, Cmd.none )
    , subscriptions = \ _ -> Sub.none
    , update = \ _ -> \ model -> ( model, Cmd.none )
    , view = view
    }

type alias Model =
  { csrf : String
  }

view : Model -> Html Never
view model =
  div [ class "form" ]
    [ Html.form 
      [ acceptCharset "UTF-8"
      , action "/players"
      , method "post" 
      ] 
      [ input 
        [ name "_csrf_token"
        , type_ "hidden"
        , value model.csrf ] []
      , div [ class "input-group" ]
        [ input 
          [ autofocus True
          , class "form-control"
          , id "player_name"
          , name "player[name]"
          , placeholder "Enter your name"
          , type_ "text"
          ] []
        , span
          [ class "input-group-btn" ] 
          [ button 
            [ class "btn btn-primary"
            , type_ "submit"
            ] 
            [ text "Enter" ]
          ]
        ]
      ]
    ]
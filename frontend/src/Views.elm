module Views exposing (..)

import LoginPage exposing (loginPage)
import Types exposing (Model, Page(..))
import Msgs exposing (Msg, Msg(SendLogin))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http

view : Model -> Html Msg
view model
  = div []
    [ mainContent model
    ]

mainContent : Model -> Html Msg
mainContent model =
    case model.page of
        Home ->
            pageHome model
        Login ->
            loginPage model
        NotFound ->
            pageNotFound


pageHome : Model -> Html Msg
pageHome model =
    div [] [ h1 [] [ text "Home Page" ]
            , text "Not implemented yet"
            ]

pageNotFound : Html Msg
pageNotFound =
    div [] [ h1 [] [ text "Not found" ]
            , text "SOrry couldn't find that page"
            ]

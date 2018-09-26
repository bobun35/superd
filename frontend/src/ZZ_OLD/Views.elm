module Views exposing (mainContent, pageHome, pageNotFound, view)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import LoginPage exposing (loginPage)
import Msgs exposing (Msg(..))
import Types exposing (Model, Page(..))


view : Model -> Browser.Document Msg
view model =
    { title = "URL Interceptor"
    , body =
        [ div []
            [ mainContent model ]
        ]
    }


mainContent : Model -> Html Msg
mainContent model =
    case model.page of
        Types.Home ->
            pageHome model

        Types.Login ->
            LoginPage.loginPage model

        Types.NotFound ->
            pageNotFound


pageHome : Model -> Html Msg
pageHome model =
    div []
        [ h1 [] [ text "Home Page" ]
        , text "Not implemented yet"
        ]


pageNotFound : Html Msg
pageNotFound =
    div []
        [ h1 [] [ text "Not found" ]
        , text "SOrry couldn't find that page"
        ]

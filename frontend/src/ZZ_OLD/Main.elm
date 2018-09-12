module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Http
import Msgs exposing (Msg(..))
import Types exposing (Flags, Model, Page(..))
import Update exposing (update)
import Views exposing (view)
import Url


init : (String) -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    (Model Login { email = "claire@superd.net", password = "pass" } flags "session2" key url
     , Cmd.none )

main : Program (String) Model Msg
main =
    Browser.application
        { init = init
        , view = Views.view
        , update = Update.update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

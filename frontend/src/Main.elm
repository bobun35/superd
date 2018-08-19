module Main exposing (main)
import Types exposing (Flags, Model, Page(Login))
import Msgs exposing (Msg, Msg(UrlChange))
import Update exposing (update)
import Views exposing (view)
import Navigation exposing (Location)
import Http
import UrlHelpers exposing (urlUpdate)



init : Flags -> Location -> ( Model, Cmd Msg )
init flags location =
    let
        ( model, urlCmd ) =
            urlUpdate location { page = Login
                                 , userModel= { email="", password="" }
                                 , apiUrl = flags.apiUrl
                                 , sessionId=""
                                 , message=""
                                 , messageVisibility="hidden" }
    in
        ( model, Cmd.batch [ urlCmd ] )

main : Program Flags Model Msg
main =
    Navigation.programWithFlags Msgs.UrlChange
        { view = Views.view
        , update = Update.update
        , subscriptions = subscriptions
        , init = init
        }

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

module Main exposing (main)
import Types exposing (Model, Page(Login))
import Msgs exposing (Msg, Msg(UrlChange))
import Update exposing (update)
import Views exposing (view)
import Navigation exposing (Location)
import Http
import UrlHelpers exposing (urlUpdate)



init : Location -> ( Model, Cmd Msg )
init location =
    let
        ( model, urlCmd ) =
            urlUpdate location { page = Login
                                 , userModel= { email="", password="" }
                                 , message=""
                                 , messageVisibility="hidden" }
    in
        ( model, Cmd.batch [ urlCmd ] )

main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { view = view
        , update = update
        , subscriptions = subscriptions
        , init = init
        }

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

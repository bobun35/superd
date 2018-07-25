module Main exposing (main)
import Models exposing (Model, Page(Login))
import Msgs exposing (Msg, Msg(UrlChange))
import Update exposing (update, urlUpdate)
import Views exposing (view)
import Navigation exposing (Location)
import Http



init : Location -> ( Model, Cmd Msg )
init location =
    let
        ( model, urlCmd ) =
            urlUpdate location { page = Login
                                 , email=""
                                 , password=""
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

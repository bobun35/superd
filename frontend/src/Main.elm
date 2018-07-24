module Main exposing (main)
import Models exposing (Model, Page(Login))
import Msgs exposing (Msg, Msg(NavMsg, UrlChange))
import Update exposing (update, urlUpdate)
import Views exposing (view)
import Navigation exposing (Location)
import Bootstrap.Navbar as Navbar
import Http



init : Location -> ( Model, Cmd Msg )
init location =
    let
        ( navState, navCmd ) =
            Navbar.initialState NavMsg

        ( model, urlCmd ) =
            urlUpdate location { navState = navState
                                 , page = Login
                                 , email=""
                                 , password=""
                                 , message=""
                                 , messageVisibility="hidden" }
    in
        ( model, Cmd.batch [ urlCmd, navCmd ] )

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
    Navbar.subscriptions model.navState NavMsg

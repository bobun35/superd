module UrlHelpers exposing (..)

import Constants exposing (homeUrl, loginUrl)
import Http exposing (Error)
import Navigation exposing (Location)
import Types exposing (Model, Page(Home, Login, NotFound))
import Msgs exposing (Msg)
import UrlParser

prependHash: String -> String
prependHash url =
    "#" ++ url

urlUpdate : Navigation.Location -> Model -> ( Model, Cmd Msg )
urlUpdate location model =
    case decode location of
        Nothing ->
            ( { model | page = NotFound }, Cmd.none )

        Just route ->
            ( { model | page = route }, Cmd.none )


decode : Location -> Maybe Page
decode location =
    UrlParser.parseHash routeParser location


routeParser : UrlParser.Parser (Page -> a) a
routeParser =
    UrlParser.oneOf
        [ UrlParser.map Types.Login UrlParser.top
        , UrlParser.map Types.Home (UrlParser.s Constants.homeUrl)
        , UrlParser.map Types.Login (UrlParser.s Constants.loginUrl)
        ]

-- TODO faire une page spécifique pour les erreurs
httpErrorResponse : Error -> Model -> ( Model, Cmd Msg )
httpErrorResponse error model =
    let
        message=toString error
    in
        Debug.log message
        ({ model | message=message, messageVisibility="visible"}
        , Navigation.newUrl( "unknown" ))
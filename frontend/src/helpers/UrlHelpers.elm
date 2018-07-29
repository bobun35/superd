module UrlHelpers exposing (..)

import Constants exposing (homeUrl, loginUrl)
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
        [ UrlParser.map Login UrlParser.top
        , UrlParser.map Home (UrlParser.s homeUrl)
        , UrlParser.map Login (UrlParser.s loginUrl)
        ]
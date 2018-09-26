module UrlHelpers exposing (httpErrorResponse, prependHash, routeParser)

import Browser.Navigation as Nav
import Constants exposing (homeUrl, loginUrl)
import Debug exposing (log)
import Http exposing (Error)
import Msgs exposing (Msg)
import Types exposing (Model, Page(..))
import Url
import Url.Parser exposing ((</>), Parser, int, map, oneOf, s, string)


prependHash : String -> String
prependHash url =
    "#" ++ url


routeParser : Parser (Page -> a) a
routeParser =
    Url.Parser.oneOf
        [ Url.Parser.map Types.Login Url.Parser.top
        , Url.Parser.map Types.Home (Url.Parser.s Constants.homeUrl)
        , Url.Parser.map Types.Login (Url.Parser.s Constants.loginUrl)
        ]



-- TODO faire une page spécifique pour les erreurs


httpErrorResponse : Error -> Model -> ( Model, Cmd Msg )
httpErrorResponse error model =
    log "CLAIRE: error received"
        ( model
        , Nav.pushUrl model.key "unknown"
        )

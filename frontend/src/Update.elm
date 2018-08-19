module Update exposing (..)

import Constants exposing (homeUrl, loginUrl)
import Debug
import HomeHelpers
import Http exposing (Error(BadStatus))
import LoginHelpers
import Types exposing (..)
import Msgs exposing (..)
import Navigation exposing (Location, newUrl)
import UrlHelpers


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of

    -- ROUTING
        UrlChange location ->
            UrlHelpers.urlUpdate location model

    -- LOG USER
        LoginResponse (Ok newSessionId) ->
             let
                updatedModel = LoginHelpers.setSessionId model newSessionId
             in
                ( updatedModel
                , HomeHelpers.sendHomeRequest updatedModel)

        LoginResponse (Err error) ->
             case error of
                BadStatus response -> if response.status.code == 401
                                      then
                                        ( model, Navigation.newUrl( loginUrl |> UrlHelpers.prependHash ))
                                      else
                                        UrlHelpers.httpErrorResponse error model
                _ -> UrlHelpers.httpErrorResponse error model

        SendLogin ->
              (model
              , LoginHelpers.sendLoginRequest model)

        SetEmail email ->
             LoginHelpers.setEmail model email

        SetPassword password ->
             LoginHelpers.setPassword model password

    -- HOME
        HomeResponse (Ok _) ->
             ( model
             , Navigation.newUrl( homeUrl |> UrlHelpers.prependHash ))

        HomeResponse (Err error) ->
            case error of
               BadStatus response -> if response.status.code == 401
                                     then
                                       ( model, Navigation.newUrl( loginUrl |> UrlHelpers.prependHash ))
                                     else
                                       UrlHelpers.httpErrorResponse error model
               _ -> UrlHelpers.httpErrorResponse error model
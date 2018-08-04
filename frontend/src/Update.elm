module Update exposing (..)

import Constants exposing (homeUrl, loginUrl)
import Debug
import Http exposing (Error(BadStatus))
import UserHelpers
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
        LoginResponse (Ok _) ->
             ( model
             , Navigation.newUrl( homeUrl |> UrlHelpers.prependHash ))

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
              , UserHelpers.sendLoginRequest model.userModel.email model.userModel.password)

        SetEmail email ->
             UserHelpers.setEmail model email

        SetPassword password ->
             UserHelpers.setPassword model password

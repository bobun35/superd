module Update exposing (..)

import Constants exposing (homeUrl, loginUrl)
import Debug
import Http
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
             let message=toString error
             in
                Debug.log message
                ({ model | message=message, messageVisibility="visible"}
                , Navigation.newUrl( "unknown" ))

        SendLogin ->
              (model
              , UserHelpers.sendLoginRequest model.userModel.email model.userModel.password)

        SetEmail email ->
             UserHelpers.setEmail model email

        SetPassword password ->
             UserHelpers.setPassword model password

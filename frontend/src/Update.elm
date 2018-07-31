module Update exposing (..)

import Constants exposing (homeUrl, loginUrl)
import Debug exposing (log)
import Http
import LoginHelpers exposing (sendLoginRequest)
import Types exposing (..)
import Msgs exposing (..)
import Navigation exposing (Location, newUrl)
import UrlHelpers exposing (prependHash, urlUpdate)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of

        LoginResponse (Ok _) ->
             ( model
             , newUrl( homeUrl |> prependHash ))

        LoginResponse (Err error) ->
             let message=toString error
             in
                log message
                ({ model | message=message, messageVisibility="visible"}
                , newUrl( "unknown" ))

        SendLogin ->
              (model
              , sendLoginRequest model.userModel.email model.userModel.password)

        SetEmail email ->
             let
                olduserModel = model.userModel
                newuserModel = { olduserModel | email=email }
             in
                ({ model | userModel= newuserModel }
                , Cmd.none)

        SetPassword password ->
             let
                olduserModel = model.userModel
                newuserModel = { olduserModel | password=password }
             in
                ({ model | userModel= newuserModel }
                , Cmd.none)

        UrlChange location ->
            urlUpdate location model

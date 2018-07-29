module Update exposing (..)

import Constants exposing (homeUrl, loginUrl)
import Http
import LoginHelpers exposing (sendLoginRequest)
import Types exposing (..)
import Msgs exposing (..)
import Navigation exposing (Location, newUrl)
import UrlHelpers exposing (prependHash, urlUpdate)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of

        LoginResponse (Ok answer) ->
             ( { model | message=answer, messageVisibility="visible"}
             , newUrl( homeUrl |> prependHash ))

        LoginResponse (Err error) ->
             ({ model | message=toString error, messageVisibility="visible"}
             , newUrl( homeUrl |> prependHash ))

        SendLogin ->
              (model
              , sendLoginRequest model.loginModel.email model.loginModel.password)

        SetEmail email ->
             let
                oldLoginModel = model.loginModel
                newLoginModel = { oldLoginModel | email=email }
             in
                ({ model | loginModel= newLoginModel }
                , Cmd.none)

        SetPassword password ->
             let
                oldLoginModel = model.loginModel
                newLoginModel = { oldLoginModel | password=password }
             in
                ({ model | loginModel= newLoginModel }
                , Cmd.none)

        UrlChange location ->
            urlUpdate location model

module Update exposing (update)

import Constants exposing (homeUrl, loginUrl)
import Debug
import HomeHelpers
import Http exposing (Error(..))
import LoginHelpers
import Msgs exposing (..)
import Types exposing (..)
import UrlHelpers
import Browser
import Browser.Navigation as Nav
import Url

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- ROUTING
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none )

        -- LOG USER
        LoginResponse (Ok newSessionId) ->
            let
                updatedModel =
                    LoginHelpers.setSessionId model newSessionId
            in
            ( updatedModel
            , HomeHelpers.sendHomeRequest updatedModel
            )

        LoginResponse (Err error) ->
            case error of
                BadStatus response ->
                    if response.status.code == 401 then
                        ( model, Cmd.none )

                    else
                        UrlHelpers.httpErrorResponse error model

                _ ->
                    UrlHelpers.httpErrorResponse error model

        SendLogin ->
            ( model
            , LoginHelpers.sendLoginRequest model
            )

        SetEmail email ->
            LoginHelpers.setEmail model email

        SetPassword password ->
            LoginHelpers.setPassword model password

        -- HOME
        HomeResponse (Ok _) ->
            ( model
            , Cmd.none
            )

        HomeResponse (Err error) ->
            case error of
                BadStatus response ->
                    if response.status.code == 401 then
                        ( model, Nav.pushUrl model.key loginUrl )

                    else
                        UrlHelpers.httpErrorResponse error model

                _ ->
                    UrlHelpers.httpErrorResponse error model

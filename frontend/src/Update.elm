module Update exposing (..)

import Http
import Models exposing (..)
import Msgs exposing (..)
import Navigation exposing (Location)
import UrlParser
import Json.Encode as Encode
import Json.Decode exposing (string)



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of

        LoginResponse (Ok answer) ->
             ( { model | message=answer, messageVisibility="visible"}
             , Cmd.none)

        LoginResponse (Err error) ->
             ({ model | message=toString error, messageVisibility="visible"}
             , Cmd.none)

        SendLogin ->
              (model
              , sendLoginRequest model.email model.password)

        SetEmail email ->
             ({ model | email=email}
             , Cmd.none)

        SetPassword password ->
             ({ model | password=password}
             , Cmd.none)

        UrlChange location ->
            urlUpdate location model



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
        , UrlParser.map Home (UrlParser.s "home")
        , UrlParser.map Login (UrlParser.s "login")
        ]

sendLoginRequest : String -> String -> Cmd Msg
sendLoginRequest email password =
  let
    url =
      "http://localhost:8080/login"

    body =
        Encode.object
            [ ( "email", Encode.string email )
            , ( "password", Encode.string password )
            ]
            |> Http.jsonBody
  in
    Http.send LoginResponse (Http.post url body string)


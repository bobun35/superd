module LoginHelpers exposing (..)

import Http exposing (Body, Expect, Request, expectStringResponse, request)
import Json.Encode as Encode
import Json.Decode exposing (string)
import Msgs exposing (Msg(LoginResponse))
import Types exposing (Model)

-- MODEL
setEmail : Model -> String -> (Model, Cmd Msg)
setEmail model email =
  setUserModel model email model.userModel.password

setPassword : Model -> String -> (Model, Cmd Msg)
setPassword model password =
  setUserModel model model.userModel.email password

setUserModel :  Model -> String -> String -> (Model, Cmd Msg)
setUserModel model email password =
  let
     oldUserModel = model.userModel
     newUserModel = { oldUserModel | email=email, password=password }
  in
     ({ model | userModel= newUserModel }
     , Cmd.none)

-- HTTP
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
    Http.send LoginResponse (postAndIgnoreResponseBody url body)

postAndIgnoreResponseBody : String -> Body -> Request ()
postAndIgnoreResponseBody url body =
    request
        { method = "POST"
        , headers = []
        , url = url
        , body = body
        , expect = ignoreResponseBody
        , timeout = Nothing
        , withCredentials = False
        }

ignoreResponseBody : Expect ()
ignoreResponseBody =
    expectStringResponse (\response -> Ok ())
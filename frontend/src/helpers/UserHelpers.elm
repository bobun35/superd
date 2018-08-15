module UserHelpers exposing (..)

import BasicAuth exposing (buildAuthorizationHeader)
import Dict
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
     ({ model | userModel = newUserModel }
     , Cmd.none)

setSessionId : Model -> String -> Model
setSessionId model newSessionId =
    { model | sessionId=newSessionId }

-- HTTP
sendLoginRequest : Model -> Cmd Msg
sendLoginRequest model =
  let
    url =
      model.apiUrl ++ "/login"

    body =
        Encode.object
            [ ( "email", Encode.string model.userModel.email )
            , ( "password", Encode.string model.userModel.password )
            ]
            |> Http.jsonBody
  in
    Http.send LoginResponse (postLoginAndReturnSessionId url model.userModel.email model.userModel.password body)

postLoginAndReturnSessionId : String -> String -> String -> Body -> Request (String)
postLoginAndReturnSessionId url email password body =
    request
        { method = "POST"
        , headers = [ buildAuthorizationHeader email password ]
        , url = url
        , body = body
        , expect = Http.expectStringResponse (extractHeader "UserSession")
        , timeout = Nothing
        , withCredentials = False
        }

ignoreResponseBody : Expect ()
ignoreResponseBody =
    expectStringResponse (\response -> Ok ())

extractHeader : String -> Http.Response String -> Result String String
extractHeader name resp =
    Dict.get name resp.headers
        |> Result.fromMaybe ("header " ++ name ++ " not found")
module LoginHelpers exposing (extractHeader, ignoreResponseBody, postLoginAndReturnSessionId, sendLoginRequest, setEmail, setPassword, setSessionId, setUserModel)

import Base64
import Debug exposing (log)
import Dict
import Http exposing (Body, Expect, Request, expectStringResponse, request)
import Json.Encode
import Msgs exposing (Msg(..))
import Types exposing (Model)



-- MODEL


setEmail : Model -> String -> ( Model, Cmd Msg )
setEmail model email =
    setUserModel model email model.userModel.password


setPassword : Model -> String -> ( Model, Cmd Msg )
setPassword model password =
    setUserModel model model.userModel.email password


setUserModel : Model -> String -> String -> ( Model, Cmd Msg )
setUserModel model email password =
    let
        oldUserModel =
            model.userModel

        newUserModel =
            { oldUserModel | email = email, password = password }
    in
    ( { model | userModel = newUserModel }
    , Cmd.none
    )


setSessionId : Model -> String -> Model
setSessionId model newSessionId =
    { model | sessionId = log "CLAIRE - newSessionId:" newSessionId }



-- HTTP


sendLoginRequest : Model -> Cmd Msg
sendLoginRequest model =
    let
        url =
            log "CLAIRE - apiUrl in sendLoginReqeust" (model.apiUrl ++ "/login")

        body =
            Json.Encode.object
                [ ( "email", Json.Encode.string model.userModel.email )
                , ( "password", Json.Encode.string model.userModel.password )
                ]
                |> Http.jsonBody
    in
    Http.send Msgs.LoginResponse (postLoginAndReturnSessionId url model.userModel.email model.userModel.password body)


postLoginAndReturnSessionId : String -> String -> String -> Body -> Request ()
postLoginAndReturnSessionId url email password body =
    Http.request
        { method = "POST"
        , headers = [ buildAuthorizationHeader email password ]
        , url = url
        , body = body

        --, expect = Http.expectStringResponse (extractHeader "User-Session")
        , expect = ignoreResponseBody
        , timeout = Nothing
        , withCredentials = False
        }


ignoreResponseBody : Expect ()
ignoreResponseBody =
    expectStringResponse (\response -> Ok ())


extractHeader : String -> Http.Response String -> Result String String
extractHeader name resp =
    let
        result =
            Dict.get (log "CLAIRE - name:" name) resp.headers
                |> Result.fromMaybe ("header " ++ name ++ " not found")
    in
    log "CLAIRE - Result" result


buildAuthorizationHeader : String -> String -> Http.Header
buildAuthorizationHeader username password =
    let
        token =
            Base64.encode (username ++ ":" ++ password)
    in
    Http.header "Authorization" ("Basic " ++ token)

module HomeHelpers exposing (..)

import Http exposing (Request, emptyBody, expectJson, get, request)
import Json.Decode exposing (string)
import Msgs exposing (..)
import Types exposing (Model)




-- HTTP
sendHomeRequest : Model -> Cmd Msg
sendHomeRequest model =
    let
        url = "http://localhost:8080/home"
        getHomeRequest = getWithSessionId url model.sessionId
    in
        Http.send HomeResponse getHomeRequest

getWithSessionId : String -> String -> Request (String)
getWithSessionId url sessionId =
    request
        { method = "GET"
        , headers = [ buildSessionHeader sessionId ]
        , url = url
        , body = emptyBody
        , expect = expectJson(string)
        , timeout = Nothing
        , withCredentials = False
        }

buildSessionHeader : String -> Http.Header
buildSessionHeader sessionId =
    Http.header "UserSession" (sessionId)


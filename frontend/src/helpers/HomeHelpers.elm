module HomeHelpers exposing (..)

import Dict exposing (Dict)
import Http exposing (Request, emptyBody, expectJson, get, request)
import Json.Decode exposing (dict, string)
import Msgs exposing (..)
import Types exposing (Model)




-- HTTP
sendHomeRequest : Model -> Cmd Msg
sendHomeRequest model =
    let
        url = model.apiUrl ++ "/home"
    in
        getWithSessionId url model.sessionId
            |> Http.send HomeResponse

getWithSessionId : String -> String -> Request (Dict String String)
getWithSessionId url sessionId =
    request
        { method = "GET"
        , headers = [ buildSessionHeader sessionId ]
        , url = url
        , body = emptyBody
        , expect = expectJson(dict string)
        , timeout = Nothing
        , withCredentials = False
        }

buildSessionHeader : String -> Http.Header
buildSessionHeader sessionId =
    Http.header "UserSession" (sessionId)


module HomeHelpers exposing (buildSessionHeader, getWithSessionId, sendHomeRequest)

import Dict exposing (Dict)
import Http exposing (Request, emptyBody, expectJson, get, request)
import Json.Decode exposing (dict, string)
import Msgs exposing (Msg(..))
import Types exposing (Model)



-- HTTP


sendHomeRequest : Model -> Cmd Msg
sendHomeRequest model =
    let
        url =
            model.apiUrl ++ "/home"
    in
    getWithSessionId url model.sessionId
        |> Http.send Msgs.HomeResponse


getWithSessionId : String -> String -> Request (Dict String String)
getWithSessionId url sessionId =
    Http.request
        { method = "GET"
        , headers = [ buildSessionHeader sessionId ]
        , url = url
        , body = Http.emptyBody
        , expect = Http.expectJson (dict string)
        , timeout = Nothing
        , withCredentials = False
        }


buildSessionHeader : String -> Http.Header
buildSessionHeader sessionId =
    Http.header "User-Session" sessionId

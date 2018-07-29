module LoginHelpers exposing (..)

import Http exposing (Body, Expect, Request, expectStringResponse, request)
import Json.Encode as Encode
import Json.Decode exposing (string)
import Msgs exposing (Msg(LoginResponse))

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
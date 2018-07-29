module LoginHelpers exposing (..)

import Http
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
    Http.send LoginResponse (Http.post url body string)

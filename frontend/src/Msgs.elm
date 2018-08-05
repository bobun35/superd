module Msgs exposing (..)

import Http
import Navigation exposing (Location)



type Msg
    =
    HomeResponse (Result Http.Error (String))
    | LoginResponse (Result Http.Error (String))
    | SendLogin
    | SetEmail String
    | SetPassword String
    | UrlChange Location


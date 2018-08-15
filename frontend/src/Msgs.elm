module Msgs exposing (..)

import Dict exposing (Dict)
import Http
import Navigation exposing (Location)



type Msg
    =
    HomeResponse (Result Http.Error (Dict String String))
    | LoginResponse (Result Http.Error (String))
    | SendLogin
    | SetEmail String
    | SetPassword String
    | UrlChange Location


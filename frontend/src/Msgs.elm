module Msgs exposing (..)

import Bootstrap.Navbar as Navbar

import Http
import Navigation exposing (Location)



type Msg
    =
    LoginResponse (Result Http.Error String)
    | NavMsg Navbar.State
    | SendLogin
    | SetEmail String
    | SetPassword String
    | UrlChange Location

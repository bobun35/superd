module Msgs exposing (..)

import Bootstrap.Navbar as Navbar

import Http
import Navigation exposing (Location)



type Msg
    = UrlChange Location
    | SendLogin
    | LoginResponse (Result Http.Error String)
    | NavMsg Navbar.State
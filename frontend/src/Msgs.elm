module Msgs exposing (Msg(..))

import Browser

import Dict exposing (Dict)
import Http
import Url

type Msg
    = HomeResponse (Result Http.Error (Dict String String))
    | LoginResponse (Result Http.Error String)
    | SendLogin
    | SetEmail String
    | SetPassword String
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url

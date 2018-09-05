module Types exposing (Flags, Model, Page(..), UserModel)

import Browser.Navigation as Nav
import Url

type alias Flags =
    { apiUrl : String }


type alias Model =
    { page : Page
    , userModel : UserModel
    , apiUrl : String
    , sessionId : String
    , key : Nav.Key
    , url : Url.Url
    }


type alias UserModel =
    { email : String
    , password : String
    }


type Page
    = Home
    | Login
    | NotFound

module Types exposing (..)

type alias Model =
    { page : Page
    , loginModel: LoginModel
    , message : String
    , messageVisibility : String
    }

type alias LoginModel =
    { email: String
    , password: String
    }

type Page
    = Home
    | Login
    | NotFound

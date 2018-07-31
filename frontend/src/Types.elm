module Types exposing (..)

type alias Model =
    { page : Page
    , userModel: userModel
    , message : String
    , messageVisibility : String
    }

type alias userModel =
    { email: String
    , password: String
    }

type Page
    = Home
    | Login
    | NotFound

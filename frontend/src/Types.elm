module Types exposing (..)

type alias Model =
    { page : Page
    , userModel: UserModel
    , message : String
    , messageVisibility : String
    }

type alias UserModel =
    { email: String
    , password: String
    }

type Page
    = Home
    | Login
    | NotFound

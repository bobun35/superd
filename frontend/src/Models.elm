module Models exposing (..)

type alias Model =
    { page : Page
    , email: String
    , password: String
    , message : String
    , messageVisibility : String
    }


type Page
    = Home
    | Login
    | NotFound

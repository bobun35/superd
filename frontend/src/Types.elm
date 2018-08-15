module Types exposing (..)

type alias Flags = { apiUrl : String }

type alias Model =
    { page : Page
    , userModel: UserModel
    , apiUrl: String
    , sessionId: String
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

module Models exposing (..)
import Bootstrap.Navbar as Navbar

type alias Model =
    { page : Page
    , navState : Navbar.State
    , email: String
    , password: String
    , message : String
    , messageVisibility : String
    }


type Page
    = Home
    | Login
    | NotFound

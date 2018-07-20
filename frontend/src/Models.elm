module Models exposing (..)
import Bootstrap.Navbar as Navbar

type alias Model =
    { page : Page
    , navState : Navbar.State
    , message : String
    , messageVisibility : String
    }


type Page
    = Home
    | Login
    | NotFound

module Data.User exposing (User, init)


type alias User =
    { firstName : String
    , lastName : String
    }


init : User
init =
    User "" ""

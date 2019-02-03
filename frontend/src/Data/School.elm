module Data.School exposing (School, init)

type alias School =
    { reference : String
    , name : String
    }


init : School
init =
    School "" ""
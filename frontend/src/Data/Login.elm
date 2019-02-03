module Data.Login exposing (..)

import Data.School exposing (School)
import Data.User exposing (User)
import Json.Decode exposing (Decoder)


type alias LoginResponseData =
    { token : String
    , user : User
    , school : School
    }


loginResponseDecoder : Decoder LoginResponseData
loginResponseDecoder =
    Json.Decode.map3 LoginResponseData
        (Json.Decode.field "token" Json.Decode.string)
        (Json.Decode.field "user" userDecoder)
        (Json.Decode.field "school" schoolDecoder)


userDecoder : Decoder User
userDecoder =
    Json.Decode.map2 User
        (Json.Decode.field "firstName" Json.Decode.string)
        (Json.Decode.field "lastName" Json.Decode.string)


schoolDecoder : Decoder School
schoolDecoder =
    Json.Decode.map2 School
        (Json.Decode.field "reference" Json.Decode.string)
        (Json.Decode.field "name" Json.Decode.string)

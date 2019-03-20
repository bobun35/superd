module Utils.Validators exposing
    ( dateRegex
    , ifNotAuthorizedString
    , stringRegex
    , verifyMaybeString
    , verifyString
    )

import Data.Form as Form
import Regex exposing (Regex)
import Validate
import Verify exposing (Validator)



{---------------------------
 USE OF R.FELTMAN VALIDATOR
----------------------------}


ifNotAuthorizedString : (subject -> String) -> error -> Validate.Validator error subject
ifNotAuthorizedString subjectToString error =
    Validate.ifFalse (\subject -> isValidString (subjectToString subject)) error


isValidString : String -> Bool
isValidString stringToCheck =
    Regex.contains validString stringToCheck


validString : Regex
validString =
    "^[a-zA-Z0-9!$%&*+?_]*$"
        |> Regex.fromStringWith { caseInsensitive = True, multiline = False }
        |> Maybe.withDefault Regex.never



{---------------------------
 USE OF VERIFY LIBRARY
----------------------------}


verifyMaybeString : Regex -> Form.Error -> Verify.Validator Form.Error (Maybe String) (Maybe String)
verifyMaybeString regex error input =
    case input of
        Just aString ->
            if Regex.contains regex aString then
                Ok (Just aString)

            else
                Err ( error, [] )

        Nothing ->
            Err ( error, [] )


verifyString : error -> Verify.Validator error String String
verifyString error input =
    if Regex.contains stringRegex input then
        Ok input

    else
        Err ( error, [] )


stringRegex : Regex
stringRegex =
    "^[a-zA-Z0-9!$%&*+?_ ()éèàçù]*$"
        |> Regex.fromStringWith { caseInsensitive = True, multiline = False }
        |> Maybe.withDefault Regex.never


dateRegex : Regex
dateRegex =
    "^[0-9]{2}/[0-9]{1,2}/[0-9]{4}$"
        |> Regex.fromStringWith { caseInsensitive = True, multiline = False }
        |> Maybe.withDefault Regex.never

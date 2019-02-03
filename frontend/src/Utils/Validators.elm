module Utils.Validators exposing (ifNotAuthorizedString)

import Validate
import Regex exposing (Regex)



ifNotAuthorizedString : (subject -> String) -> error -> Validate.Validator error subject
ifNotAuthorizedString subjectToString error =
    Validate.ifFalse (\subject -> isValidString (subjectToString subject)) error


isValidString :  String -> Bool
isValidString stringToCheck =
    Regex.contains validString stringToCheck


validString : Regex
validString =
    "^[a-zA-Z0-9!$%&*+?_]*$"
        |> Regex.fromStringWith { caseInsensitive = True, multiline = False }
        |> Maybe.withDefault Regex.never

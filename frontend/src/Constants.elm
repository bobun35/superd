module Constants exposing (..)

hashed : String -> String
hashed localUrl =
    "/#" ++ localUrl

homeUrl : String
homeUrl =
    "/home"

loginUrl : String
loginUrl =
    "/login"

logoutUrl : String
logoutUrl =
    "/logout"

budgetUrl : Int -> String
budgetUrl budgetId =
    "/budget/" ++ (String.fromInt budgetId)

budgetDetailUrl : String
budgetDetailUrl =
    "/budget/details"

budgetOperationUrl : String
budgetOperationUrl =
    "/budget/operations"

operationUrl : Int -> String
operationUrl budgetId =
    "/budget/" ++ (String.fromInt budgetId) ++ "/operations"

errorUrl : String
errorUrl =
    "/error"


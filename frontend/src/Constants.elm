module Constants exposing (homeUrl, loginUrl, budgetUrl, budgetOperationUrl, budgetDetailUrl, logoutUrl, errorUrl)


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

errorUrl : String
errorUrl =
    "/error"


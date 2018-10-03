module Constants exposing (homeUrl, loginUrl, operationsUrl, logoutUrl)


homeUrl : String
homeUrl =
    "/home"

loginUrl : String
loginUrl =
    "/login"

logoutUrl : String
logoutUrl =
    "/logout"

operationsUrl : Int -> String
operationsUrl budgetId =
    "/" ++ (String.fromInt budgetId) ++ "/operations"

module Constants exposing (homeUrl, loginUrl, budgetUrl, logoutUrl)


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

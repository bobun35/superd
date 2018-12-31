module Constants exposing (budgetDetailUrl, budgetOperationUrl, budgetUrl, budgetUrlWithId, errorUrl, hashed, homeUrl, loginUrl, logoutUrl, operationUrl)


hashed : String -> String
hashed localUrl =
    "/#" ++ localUrl


homeUrl =
    "/home"


loginUrl =
    "/login"


logoutUrl =
    "/logout"


budgetUrl =
    "/budget"


budgetUrlWithId : Int -> String
budgetUrlWithId budgetId =
    budgetUrl ++ "/" ++ String.fromInt budgetId


budgetDetailUrl =
    "/budget/details"


budgetOperationUrl =
    "/budget/operations"


operationUrl : Int -> String
operationUrl budgetId =
    "/budget/" ++ String.fromInt budgetId ++ "/operations"


errorUrl =
    "/error"

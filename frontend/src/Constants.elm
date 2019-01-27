module Constants exposing (..)


hashed : String -> String
hashed localUrl =
    "/#" ++ localUrl


budgetDetailUrl =
    "/budget/details"


budgetOperationUrl =
    "/budget/operations"


budgetTypesUrl =
    "/budget-types"


budgetUrl =
    "/budget"


budgetUrlWithId : Int -> String
budgetUrlWithId budgetId =
    budgetUrl ++ "/" ++ String.fromInt budgetId

creditorsUrl =
    "/creditors"

errorUrl =
    "/error"


homeUrl =
    "/home"


loginUrl =
    "/login"


logoutUrl =
    "/logout"


operationUrl : Int -> String
operationUrl budgetId =
    "/budget/" ++ String.fromInt budgetId ++ "/operations"

recipientsUrl =
    "/recipients"

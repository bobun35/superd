module BudgetTests exposing (viewTests)

import Data.Budget exposing (Budget(..))
import Data.Form as Form
import Expect
import Test exposing (Test, describe, test)


testValidInfo =
    { name = "budget name"
    , reference = "test reference"
    , budgetType = "fonctionnement"
    , recipient = "maternelle"
    , creditor = "mairie"
    , comment = "no comment"
    }


viewTests : Test
viewTests =
    describe "budget page elements"
        [ test "operation with valid budget info should pass the verification test" <|
            \() ->
                testValidInfo
                    |> Data.Budget.verifyInfo
                    |> Expect.equal
                        (Ok testValidInfo)
        ]

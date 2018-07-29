module LoginTests exposing (tests)

import Expect
import Html.Events exposing (onInput)
import LoginPage exposing (..)

import Html
import Html.Attributes as Attr
import Models exposing (Model, Page(Login))
import Msgs exposing (Msg(SendLogin))
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector exposing (attribute, class, tag, text)

testModel: Model
testModel =
    { page = Login
    , email=""
    , password=""
    , message=""
    , messageVisibility="hidden"
    }

tests: Test
tests =
    describe "login page elements"
        [ test "the email input should be present" <|
            \() ->
                loginPage testModel
                    |> Query.fromHtml
                    |> Query.findAll [ tag "input" ]
                    |> Query.count (Expect.equal 2)
        , test "connection button should be present" <|
                    \() ->
                        loginPage testModel
                            |> Query.fromHtml
                            |> Query.has [ class "button" ]
        ]
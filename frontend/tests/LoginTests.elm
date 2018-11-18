module LoginTests exposing (..)

import Expect
import Html.Events exposing (onInput)

import Html
import Html.Attributes as Attr exposing (placeholder)
import Test exposing (Test, describe, only, test, todo)
import Test.Html.Query as Query
import Test.Html.Event as Event
import Test.Html.Selector exposing (attribute, class, containing, tag, text)
import OperationMuv
import Main exposing (..)
import Url


testModel: Model
testModel =
    { key = Nothing
    , url = testUrl
    , page = LoginPage
    , email = ""
    , password = ""
    , token = "token"
    , school = School "" ""
    , budgets = []
    , user =  User "" ""
    , currentOperation = OperationMuv.initModel
    , currentBudget = Nothing
    }

testUrl: Url.Url
testUrl =
    { protocol = Url.Http
    , host = "host"
    , port_ = Nothing
    , path = "path"
    , query = Nothing
    , fragment = Nothing
    }


viewTests: Test
viewTests =
    describe "login page elements"
        [ test "the email input should be present" <|
            \() ->
                viewLogin testModel
                    |> Query.fromHtml
                    |> Query.findAll [ tag "input" ]
                    |> Query.count (Expect.equal 2)

        , test "connection button should be present" <|
            \() ->
                viewLogin testModel
                    |> Query.fromHtml
                    |> Query.has [ class "button" ]

        , test "entering email should trigger SetEmailInModel" <|
            \() ->
                viewLogin testModel
                    |> Query.fromHtml
                    |> Query.findAll [ tag "input" ]
                    |> Query.first
                    |> Event.simulate (Event.input "cats@mail.com")
                    |> Event.expect (SetEmailInModel "cats@mail.com")

        , test "SetEmailInModel should update model" <|
            \() ->
                let expectedModel = { testModel | email="cats@mail.com" }
                in
                    testModel
                        |> update (SetEmailInModel "cats@mail.com")
                        |> Tuple.first
                        |> Expect.equal expectedModel

        , test "entering password should trigger SetPasswordInModel" <|
            \() ->
                viewLogin testModel
                    |> Query.fromHtml
                    |> Query.findAll [ tag "input" ]
                    |> Query.index 1
                    |> Event.simulate (Event.input "myPass")
                    |> Event.expect (SetPasswordInModel "myPass")

        , test "SetPasswordInModel should update model" <|
            \() ->
                let expectedModel = { testModel | password="myPass" }
                in
                    testModel
                        |> update (SetPasswordInModel "myPass")
                        |> Tuple.first
                        |> Expect.equal expectedModel
        ]

apiTests: Test
apiTests =
    describe "login request to /login endpoint"
        [ todo "click on connection button should trigger http request to login endpoint"
        ]

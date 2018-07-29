module LoginTests exposing (..)

import Expect
import Html.Events exposing (onInput)
import LoginHelpers exposing (sendLoginRequest)
import LoginPage exposing (..)

import Html
import Html.Attributes as Attr exposing (placeholder)
import Types exposing (Model, Page(Login))
import Msgs exposing (Msg(SendLogin, SetEmail, SetPassword))
import Test exposing (Test, describe, only, test, todo)
import Test.Html.Query as Query
import Test.Html.Event as Event
import Test.Html.Selector exposing (attribute, class, containing, tag, text)
import Update exposing (update)

testModel: Model
testModel =
    { page = Login
    , loginModel = { email="", password=""}
    , message=""
    , messageVisibility="hidden"
    }

viewTests: Test
viewTests =
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

        , test "entering email should trigger SetEmail" <|
            \() ->
                loginPage testModel
                    |> Query.fromHtml
                    |> Query.findAll [ tag "input" ]
                    |> Query.first
                    |> Event.simulate (Event.input "cats@mail.com")
                    |> Event.expect (SetEmail "cats@mail.com")

        , test "SetEmail should update model" <|
            \() ->
                let expectedModel = { page = Login
                                    , loginModel = { email="cats@mail.com", password=""}
                                    , message=""
                                    , messageVisibility="hidden"
                                    }
                in
                    testModel
                        |> update (SetEmail "cats@mail.com")
                        |> Tuple.first
                        |> Expect.equal expectedModel

        , test "entering password should trigger SetPassword" <|
            \() ->
                loginPage testModel
                    |> Query.fromHtml
                    |> Query.findAll [ tag "input" ]
                    |> Query.index 1
                    |> Event.simulate (Event.input "myPass")
                    |> Event.expect (SetPassword "myPass")

        , test "SetPassword should update model" <|
            \() ->
                let expectedModel = { page = Login
                                    , loginModel = { email="", password="myPass"}
                                    , message=""
                                    , messageVisibility="hidden"
                                    }
                in
                    testModel
                        |> update (SetPassword "myPass")
                        |> Tuple.first
                        |> Expect.equal expectedModel
        ]

apiTests: Test
apiTests =
    describe "login request to /login endpoint"
        [ test "click on connection button should trigger http request to login endpoint" <|
            \() ->
                sendLoginRequest "test@email.com" "myPass"
        ]

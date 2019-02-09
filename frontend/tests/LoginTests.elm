module LoginTests exposing (testModel, testUrl, viewTests)

import Expect
import Pages.Login exposing (..)
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector exposing (class, tag)
import Url


testModel =
    { email = ""
    , password = ""
    , formErrors = []
    }


testUrl : Url.Url
testUrl =
    { protocol = Url.Http
    , host = "host"
    , port_ = Nothing
    , path = "path"
    , query = Nothing
    , fragment = Nothing
    }


viewTests : Test
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
                    |> Event.expect (SetEmail "cats@mail.com")
        , test "SetEmailInModel should update model" <|
            \() ->
                let
                    expectedModel =
                        { testModel | email = "cats@mail.com" }
                in
                testModel
                    |> update (SetEmail "cats@mail.com")
                    |> Tuple.first
                    |> Expect.equal expectedModel
        , test "entering password should trigger SetPasswordInModel" <|
            \() ->
                viewLogin testModel
                    |> Query.fromHtml
                    |> Query.findAll [ tag "input" ]
                    |> Query.index 1
                    |> Event.simulate (Event.input "myPass")
                    |> Event.expect (SetPassword "myPass")
        , test "SetPasswordInModel should update model" <|
            \() ->
                let
                    expectedModel =
                        { testModel | password = "myPass" }
                in
                testModel
                    |> update (SetPassword "myPass")
                    |> Tuple.first
                    |> Expect.equal expectedModel
        ]

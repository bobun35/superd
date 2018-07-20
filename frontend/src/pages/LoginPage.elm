module LoginPage exposing (loginPage)

import Html exposing (Html, h2, text)
import Html.Attributes exposing (for, style)
import Models exposing (Model)
import Msgs exposing (Msg(SendLogin))
import Bootstrap.Form as Form exposing (label)
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Select as Select
import Bootstrap.Form.Checkbox as Checkbox
import Bootstrap.Form.Radio as Radio
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Form.Fieldset as Fieldset
import Bootstrap.Button as Button
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.ListGroup as Listgroup
import Html.Events exposing (onClick)

loginPage : Model -> List (Html Msg)
loginPage model =
    [ h2 [] [ text "Login" ]
    , Grid.row [ Row.centerXs ]
        [ Grid.col [ Col.xs3 ] [ text "" ]
        , Grid.col [ Col.xs6 ]
            [ Form.form []
                [ Form.group []
                    [ Form.label [for "myemail"] [ text "Email address"]
                    , Input.email [ Input.id "myemail" ]
                    , Form.help [] [ text "We'll never share your email with anyone else." ]
                    ]
                , Form.group []
                    [ Form.label [for "mypwd"] [ text "Password"]
                    , Input.password [ Input.id "mypwd" ]
                    ]
                , Button.button
                            [ Button.primary
                            , Button.block
                            , Button.attrs [ onClick SendLogin ]
                            ]
                            [ text "Se connecter" ]
                ]
            ]
        , Grid.col [ Col.xs3 ]  [ text "" ]
        ]
    ]
module LoginPage exposing (loginPage)

import Html exposing (Html, div, h2, text)
import Html.Attributes exposing (class, for, style)
import Models exposing (Model)
import Msgs exposing (Msg(SendLogin, SetEmail, SetPassword))
import Html.Events exposing (onClick)


loginPage : Model -> Html Msg
loginPage model =
    div [] [ h2 [] [ text "Login" ]
           , div [ class "columns"] [ div [ class "column" ] [ text "column 1" ]
                                     , div [ class "column" ] [ text "column 2" ]
                                     , div [ class "column" ] [ text "column 3" ]
                                    ]
            ]
    {--    , Grid.col [ Col.xs6 ]
            [ Form.form []
                [ Form.group []
                    [ Form.label [for "email"] [ text "Email address"]
                    , Input.email [ Input.id "email"
                                  , Input.placeholder "Email"
                                  , Input.onInput SetEmail
                                  , Input.value model.email]
                    , Form.help [] [ text "We'll never share your email with anyone else." ]
                    ]
                , Form.group []
                    [ Form.label [for "pwd"] [ text "Password"]
                    , Input.password [ Input.id "pwd"
                                     , Input.placeholder "Password"
                                     , Input.onInput SetPassword
                                     , Input.value model.password]
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
    --}
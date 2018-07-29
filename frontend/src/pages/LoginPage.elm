module LoginPage exposing (loginPage)

import Html exposing (Html, a, div, h2, i, input, p, span, text)
import Html.Attributes exposing (class, for, placeholder, style, type_, value)
import Types exposing (Model)
import Msgs exposing (Msg(SendLogin, SetEmail, SetPassword))
import Html.Events exposing (onClick, onInput)


loginPage : Model -> Html Msg
loginPage model =
    div [] [ h2 [] [ text "Login" ]
           , div [ class "columns"]
                 [  div [ class "column" ] []
                 , div [ class "column" ] [ emailInput model
                                          , passwordInput model
                                          , submitLoginButton ]
                 , div [ class "column" ] []
                 ]
           ]

emailInput : Model -> Html Msg
emailInput model =
    div [ class "field"]
        [ p [class "control has-icons-left has-icons-right"]
            [ input [ class "input", type_  "email", placeholder "Email", value model.loginModel.email, onInput SetEmail ] []
            ,span [ class "icon is-small is-left"] [ i [class "fas fa-envelope"] [] ]
            ,span [ class "icon is-small is-right"] [ i [class "fas fa-check"] [] ]
            ]
        ]

passwordInput : Model -> Html Msg
passwordInput model =
    div [ class "field"]
        [ p [ class "control has-icons-left" ]
            [ input [ class "input", type_  "password", placeholder "Password", value model.loginModel.password, onInput SetPassword ] []
            ,span [ class "icon is-small is-left"] [ i [class "fas fa-lock"] [] ]
            ]
        ]

submitLoginButton: Html Msg
submitLoginButton =
    a [ class "button is-info is-rounded is-block", onClick SendLogin ] [ text "Se connecter"]
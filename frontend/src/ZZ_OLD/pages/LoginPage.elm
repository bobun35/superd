module LoginPage exposing (loginPage)

import Html exposing (Html, a, div, h1, h2, i, input, p, span, text)
import Html.Attributes exposing (class, for, placeholder, style, type_, value)
import Html.Events exposing (onClick, onInput)
import Msgs exposing (Msg(..))
import Types exposing (Model)


loginPage : Model -> Html Msg
loginPage model =
    div [ class "columns" ]
        [ div [ class "column" ] []
        , div [ class "column" ]
            [ h1 [ class "is-size-1 has-text-link has-text-centered\n                                              has-text-weight-light padding-bottom" ]
                [ text "la super directrice, c'est toi !" ]
            , emailInput model
            , passwordInput model
            , submitLoginButton
            ]
        , div [ class "column" ] []
        ]


emailInput : Model -> Html Msg
emailInput model =
    div [ class "field" ]
        [ p [ class "control has-icons-left has-icons-right" ]
            [ input [ class "input", type_ "email", placeholder "Email", value "claire@superd.net", onInput SetEmail ] []
            , span [ class "icon is-small is-left" ] [ i [ class "fas fa-envelope" ] [] ]
            , span [ class "icon is-small is-right" ] [ i [ class "fas fa-check" ] [] ]
            ]
        ]


passwordInput : Model -> Html Msg
passwordInput model =
    div [ class "field" ]
        [ p [ class "control has-icons-left" ]
            [ input [ class "input", type_ "password", placeholder "Password", value "pass", onInput SetPassword ] []
            , span [ class "icon is-small is-left" ] [ i [ class "fas fa-lock" ] [] ]
            ]
        ]


submitLoginButton : Html Msg
submitLoginButton =
    div [ class "has-text-centered" ]
        [ a [ class "button is-info is-rounded", onClick SendLogin ] [ text "Se connecter" ]
        ]

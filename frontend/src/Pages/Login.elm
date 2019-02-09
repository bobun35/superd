module Pages.Login exposing (FormError, Model, Msg(..), Notification(..), update, viewLogin)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Utils.Validators
import Validate



{-------------------------
        MODEL
--------------------------}


type alias Model a =
    { a
        | email : String
        , password : String
        , formErrors : List FormError
    }


type FormField
    = Email
    | Password


type alias FormError =
    ( FormField, String )


type Notification
    = NoNotification
    | LoginRequested


type Msg
    = LoginButtonClicked
    | SetEmail String
    | SetPassword String



{-------------------------
        UPDATE
--------------------------}


update : Msg -> Model a -> ( Model a, Notification )
update msg model =
    case msg of
        LoginButtonClicked ->
            case Validate.validate loginFormValidator model of
                Ok _ ->
                    ( { model | formErrors = [] }
                    , LoginRequested
                    )

                Err errors ->
                    ( { model | formErrors = errors }
                    , NoNotification
                    )

        SetEmail email ->
            ( { model | email = email }
            , NoNotification
            )

        SetPassword password ->
            ( { model | password = password }
            , NoNotification
            )



{-------------------------
        HELPERS
--------------------------}


loginFormValidator : Validate.Validator ( FormField, String ) (Model a)
loginFormValidator =
    Validate.all
        [ Validate.firstError
            [ Validate.ifBlank .email ( Email, "Merci d'entrer votre adresse mail." )
            , Validate.ifInvalidEmail .email (\_ -> ( Email, "Ce mail n'est pas valide." ))
            ]
        , Validate.firstError
            [ Validate.ifBlank .password ( Password, "Merci d'entrer votre mot de passe" )
            , Utils.Validators.ifNotAuthorizedString .password
                ( Password
                , "Mot de passe invalide, caractères autorisés: "
                    ++ "aA -> zZ, 1 -> 9, !$%&*+?_"
                )
            ]
        ]



{-------------------------
        VIEW
--------------------------}


viewLogin : Model a -> Html Msg
viewLogin model =
    section [ class "hero is-login-hero is-fullheight" ]
        [ div [ class "hero-body" ]
            [ div [ class "columns is-fullwidth" ]
                [ div [ class "column is-two-thirds" ] []
                , div [ class "column" ]
                    [ h1 [ class "login-title has-text-centered" ]
                        [ text "budgets équilibrés ou pas !" ]
                    , viewEmailInput model
                    , viewPasswordInput model
                    , viewLoginSubmitButton
                    ]
                ]
            ]
        ]


viewEmailInput : Model a -> Html Msg
viewEmailInput model =
    div [ class "field" ]
        [ p [ class "control has-icons-left has-icons-right" ]
            [ input [ class "input is-rounded", type_ "email", placeholder "Email", value model.email, onInput SetEmail ] []
            , span [ class "icon is-small is-left" ] [ i [ class "fas fa-envelope" ] [] ]
            , span [ class "icon is-small is-right" ] [ i [ class "fas fa-check" ] [] ]
            ]
        , viewFormErrors Email model.formErrors
        ]


viewFormErrors : FormField -> List FormError -> Html msg
viewFormErrors field errors =
    errors
        |> List.filter (\( fieldError, _ ) -> fieldError == field)
        |> List.map (\( _, error ) -> li [] [ text error ])
        |> ul [ class "form-errors" ]


viewPasswordInput : Model a -> Html Msg
viewPasswordInput model =
    div [ class "field" ]
        [ p [ class "control has-icons-left" ]
            [ input [ class "input is-rounded", type_ "password", placeholder "Password", value model.password, onInput SetPassword ] []
            , span [ class "icon is-small is-left" ] [ i [ class "fas fa-lock" ] [] ]
            ]
        , viewFormErrors Password model.formErrors
        ]


viewLoginSubmitButton : Html Msg
viewLoginSubmitButton =
    div [ class "has-text-centered" ]
        [ div [ class "button is-info is-rounded", onClick LoginButtonClicked ] [ text "Se connecter" ]
        ]

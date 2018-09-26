module Main exposing (main)

import Base64
import Browser
import Browser.Navigation as Nav
import Debug exposing (log)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder, field, string)
import Json.Encode
import RemoteData
import Task
import Url
import Url.Builder
import Url.Parser exposing (Parser, map, oneOf, parse, s, top)



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL

type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , page : Page
    , email : String
    , password : String
    , token : String
    , school : School
    , budget : String
    , user : User
    }

type alias User =
    { firstName: String
    , lastName: String
    }

initUser: User
initUser =
    User "" ""

type alias School =
    { reference: String
    , name: String
    }

initSchool: School
initSchool =
    School "" ""

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model key url LoginPage "claire@superd.net" "pass123" "" initSchool "" initUser, Cmd.none )



-- INTERNAL PAGES


type Page
    = LoginPage
    | HomePage
    | NotFoundPage


pageParser : Parser (Page -> a) a
pageParser =
    oneOf
        [ map LoginPage top
        , map LoginPage (s "login")
        , map HomePage (s "home")
        ]


toPage : Url.Url -> Page
toPage url =
    Maybe.withDefault NotFoundPage (parse pageParser url)



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ApiGetHomeResponse (RemoteData.WebData String)
    | SetEmailInModel String
    | SetPasswordInModel String
    | LoginButtonClicked
    | ApiPostLoginResponse (RemoteData.WebData LoginResponseData)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- ROUTING
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            let
                newModel =
                    { model
                        | url = url
                        , page = toPage url
                    }
            in
            ( newModel
            , triggerOnLoadAction newModel
            )

        -- LOGIN
        SetEmailInModel email ->
            ( { model | email = email }
            , Cmd.none
            )

        SetPasswordInModel password ->
            ( { model | password = password }
            , Cmd.none
            )

        LoginButtonClicked ->
            ( model
            , apiPostLogin model
            )

        ApiPostLoginResponse responseData ->
            case responseData of
                RemoteData.Success data ->
                    ( { model | token = data.token, user = data.user, school = data.school }
                    , Nav.pushUrl model.key "/home"
                    )
                _ ->
                    let
                      _ = log "postLoginHasFailed, responseData" responseData   
                    in
                        ( model, Cmd.none )

        -- HOME
        ApiGetHomeResponse responseBudget ->
            case responseBudget of
                RemoteData.Success budget ->
                    ( { model | budget = budget }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )


triggerOnLoadAction : Model -> Cmd Msg
triggerOnLoadAction model =
    case model.page of
        HomePage ->
            apiGetHome model
        _ ->
            Cmd.none



-- API POST TO LOGIN ENDPOINT

apiPostLogin : Model -> Cmd Msg
apiPostLogin model =
    postWithBasicAuthorizationHeader model "/login" Http.emptyBody loginResponseDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiPostLoginResponse

postWithBasicAuthorizationHeader : Model -> String -> Http.Body -> Decoder a  -> Http.Request a
postWithBasicAuthorizationHeader model url body decoder =
    Http.request
        { method = "POST"
        , headers = [ buildBasicAuthorizationHeader model.email model.password ]
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }

buildBasicAuthorizationHeader : String -> String -> Http.Header
buildBasicAuthorizationHeader email password =
    let
        token =
            Base64.encode (email ++ ":" ++ password)
    in
    Http.header "Authorization" ("Basic " ++ token)

type alias LoginResponseData =
    { token: String
    , user: User
    , school: School
    }

loginResponseDecoder : Decoder LoginResponseData
loginResponseDecoder =
    Json.Decode.map3 LoginResponseData
        (field "token" Json.Decode.string)
        (field "user" userDecoder)
        (field "school" schoolDecoder)

userDecoder : Decoder User
userDecoder =
    Json.Decode.map2 User
        (field "firstName" Json.Decode.string)
        (field "lastName" Json.Decode.string)

schoolDecoder : Decoder School
schoolDecoder =
    Json.Decode.map2 School
        (field "reference" Json.Decode.string)
        (field "name" Json.Decode.string)



-- API GET TO HOME ENDPOINT

apiGetHome : Model -> Cmd Msg
apiGetHome model =
    getWithToken model.token "/home" Http.emptyBody budgetDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiGetHomeResponse


getWithToken : String -> String -> Http.Body -> Decoder a -> Http.Request a
getWithToken token url body decoder =
    Http.request
        { method = "GET"
        , headers = [ buildTokenHeader token ]
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }

buildTokenHeader : String -> Http.Header
buildTokenHeader token =
    Http.header "token" token


budgetDecoder : Decoder String
budgetDecoder =
    field "budget" Json.Decode.string



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Still lots to do !!"
    , body =
        [ div []
            [ mainContent model ]
        ]
    }


viewLink : String -> Html msg
viewLink path =
    li [] [ a [ href path ] [ text path ] ]


mainContent : Model -> Html Msg
mainContent model =
    case model.page of
        HomePage ->
            viewHome model

        LoginPage ->
            viewLogin model

        NotFoundPage ->
            viewPageNotFound


viewHome : Model -> Html Msg
viewHome model =
    div []
        [ nav [ class "navbar is-blue" ]
            [ div [ class "navbar-brand" ]
                []
            , div [ class "navbar-menu" ]
                []
            ]
        , h1 [] [ text "Home Page" ]
        , text <| "siret école: " ++ model.school.name
        ]


viewPageNotFound : Html Msg
viewPageNotFound =
    div []
        [ h1 [] [ text "Not found" ]
        , text "SOrry couldn't find that page"
        ]


viewLogin : Model -> Html Msg
viewLogin model =
    section [ class "hero is-fullheight has-background-white" ]
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


viewEmailInput : Model -> Html Msg
viewEmailInput model =
    div [ class "field" ]
        [ p [ class "control has-icons-left has-icons-right" ]
            [ input [ class "input", type_ "email", placeholder "Email", value model.email, onInput SetEmailInModel ] []
            , span [ class "icon is-small is-left" ] [ i [ class "fas fa-envelope" ] [] ]
            , span [ class "icon is-small is-right" ] [ i [ class "fas fa-check" ] [] ]
            ]
        ]


viewPasswordInput : Model -> Html Msg
viewPasswordInput model =
    div [ class "field" ]
        [ p [ class "control has-icons-left" ]
            [ input [ class "input", type_ "password", placeholder "Password", value model.password, onInput SetPasswordInModel ] []
            , span [ class "icon is-small is-left" ] [ i [ class "fas fa-lock" ] [] ]
            ]
        ]


viewLoginSubmitButton : Html Msg
viewLoginSubmitButton =
    div [ class "has-text-centered" ]
        [ div [ class "button is-info is-rounded", onClick LoginButtonClicked ] [ text "Se connecter" ]
        ]

module Main exposing (main)

import Base64
import Browser
import Browser.Navigation as Nav
import Debug exposing (log)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode exposing (Decoder)
import Json.Decode.Extra
import Json.Encode
import RemoteData
import Task
import Url
import Url.Builder
import Url.Parser exposing (Parser, map, oneOf, parse, s, top, int, (</>))
import Constants exposing (homeUrl, loginUrl, budgetUrl, logoutUrl)



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
    , budgets : List BudgetSummary
    , user : User
    , currentBudget : Maybe Budget
    }

type alias BudgetSummary =
    { id: Int
    , name: String
    , reference: String
    , budgetType: String
    , recipient: String
    , realRemaining: Float
    , virtualRemaining: Float
    }

type alias Budget =
    { id: Int
    , name: String
    , reference: String
    , status: String
    , budgetType: String
    , recipient: String
    , creditor: String
    , comment: String
    , realRemaining: Float
    , virtualRemaining: Float
    }

initBudgets : List BudgetSummary
initBudgets = []

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
    ( Model key url 
        LoginPage 
        "claire@superd.net" 
        "pass123" 
        "" 
        initSchool 
        initBudgets 
        initUser
        Nothing
    , Cmd.none )

 
-- INTERNAL PAGES


type Page
    = LoginPage
    | HomePage
    | BudgetPage Int
    | NotFoundPage


pageParser : Parser (Page -> a) a
pageParser =
    oneOf
        [ map LoginPage top
        , map LoginPage (s "login")
        , map HomePage (s "home")
        , map BudgetPage (s "budget" </> int)
        ]


toPage : Url.Url -> Page
toPage url =
    Maybe.withDefault NotFoundPage (parse pageParser url)



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | ApiGetHomeResponse (RemoteData.WebData (List BudgetSummary))
    | SetEmailInModel String
    | SetPasswordInModel String
    | LoginButtonClicked
    | ApiPostLoginResponse (RemoteData.WebData LoginResponseData)
    | SelectBudgetClicked Int
    | LogoutButtonClicked
    | ApiPostLogoutResponse (RemoteData.WebData ())


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
 
        --LOGOUT
        LogoutButtonClicked ->
            let
                token = model.token
            in
                ( model
                , apiPostLogout token
                )
        
        ApiPostLogoutResponse responseData ->
            ( { model | token = ""
                        , email = ""
                        , password = ""
                        , user = initUser
                        , school = initSchool
                        , budgets = initBudgets }
            , Nav.pushUrl model.key loginUrl )

        -- HOME
        ApiGetHomeResponse response ->
            case response of
                RemoteData.Success budgets ->
                    ( { model | budgets = budgets }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )
        
        -- BUDGET
        SelectBudgetClicked budgetId ->
            -- TODO CLAIRE FAIRE UN GET BUDGET (devrait renvoyer budget + operations)
            ( model
            , Cmd.none)


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
    postWithBasicAuthorizationHeader model loginUrl Http.emptyBody loginResponseDecoder
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
        (Json.Decode.field "token" Json.Decode.string)
        (Json.Decode.field "user" userDecoder)
        (Json.Decode.field "school" schoolDecoder)

userDecoder : Decoder User
userDecoder =
    Json.Decode.map2 User
        (Json.Decode.field "firstName" Json.Decode.string)
        (Json.Decode.field "lastName" Json.Decode.string)

schoolDecoder : Decoder School
schoolDecoder =
    Json.Decode.map2 School
        (Json.Decode.field "reference" Json.Decode.string)
        (Json.Decode.field "name" Json.Decode.string)



-- API GET TO HOME ENDPOINT

apiGetHome : Model -> Cmd Msg
apiGetHome model =
    getWithToken model.token homeUrl Http.emptyBody budgetsDecoder
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

budgetsDecoder : Decoder (List BudgetSummary)
budgetsDecoder =
    Json.Decode.field "budgetSummaries" (Json.Decode.list budgetSummaryDecoder)

budgetSummaryDecoder: Decoder BudgetSummary
budgetSummaryDecoder =
    Json.Decode.succeed BudgetSummary
        |> Json.Decode.Extra.andMap (Json.Decode.field "id" Json.Decode.int)
        |> Json.Decode.Extra.andMap (Json.Decode.field "name" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.field "reference" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.field "type" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.field "recipient" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.field "realRemaining" Json.Decode.float)
        |> Json.Decode.Extra.andMap (Json.Decode.field "virtualRemaining" Json.Decode.float)


-- API LOGOUT
apiPostLogout : String -> Cmd Msg
apiPostLogout token =
    postWithTokenEmptyResponseExpected token logoutUrl Http.emptyBody
        |> RemoteData.sendRequest
        |> Cmd.map ApiPostLogoutResponse


postWithTokenEmptyResponseExpected : String -> String -> Http.Body -> Http.Request ()
postWithTokenEmptyResponseExpected token url body =
    Http.request
        { method = "POST"
        , headers = [ buildTokenHeader token ]
        , url = url
        , body = body
        , expect = ignoreResponseBody
        , timeout = Nothing
        , withCredentials = False
        }

ignoreResponseBody : Http.Expect ()
ignoreResponseBody =
    Http.expectStringResponse (\response -> Ok ())

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

mainContent : Model -> Html Msg
mainContent model =
    case model.page of
        HomePage ->
            viewHome model

        LoginPage ->
            viewLogin model

        BudgetPage int ->
            viewBudget model

        NotFoundPage ->
            viewPageNotFound

-- HOME VIEW
viewHome : Model -> Html Msg
viewHome model =
    div []
        [viewNavBar model
        , div [ class "hero is-home-hero is-fullheight"]
              [div [class "hero-header"][ div [class "has-text-centered"][viewTitle "les budgets"]]
              ,div [class "hero-body is-home-hero-body"] [div [class "section"]
                                            [div [class "container is-fluid"]
                                                 [viewBudgetsPerFamily "fonctionnement" model.budgets]
                                            ]
                                        ]
              ]
        ]

viewTitle : String -> Html Msg
viewTitle title =
    h1 [class "is-title has-text-centered"] [ text title ]

viewNavBar : Model -> Html Msg
viewNavBar model =
    nav [ class "navbar is-blue" ]
            [ div [ class "navbar-brand" ]
                  [ div [class "navbar-item"]
                        [ text "superdirectrice (parfois)"]
                  ]
            , div [ class "navbar-menu" ]
                [div [class "navbar-end"]
                     [ div [class "navbar-item navbar-school"] [text <| "école: " ++ model.school.name]
                     , div [class "navbar-item navbar-user has-dropdown is-hoverable"]
                          [a [class "navbar-link"][text model.user.firstName ]
                          , div [class "navbar-dropdown is-right"]
                                [div [class "navbar-item is-hoverable"
                                   , onClick LogoutButtonClicked] [text "Se déconnecter"]]
                          ]
                     ]
                ]
            ]

viewBudgetsPerFamily : String -> (List BudgetSummary) -> Html Msg
viewBudgetsPerFamily family budgets =
    div [class "container butter-color is-family-container has-text-centered"]
        [ h2 [class "is-size-3 has-text-weight-light is-family-container-title"] [text ("budgets " ++ family)]
        , div [] (List.map viewBudgetSummary budgets) ]

viewBudgetSummary : BudgetSummary -> Html Msg
viewBudgetSummary budget =
    div [ class "card padding-left is-budget-summary"]
        [ header [class "card-header"]
                 [p [class "card-header-title is-centered"][text budget.name]]
        , div [class "card-content" ]
              [div [class "content has-text-left is-budget-summary-content"]
                   [ viewBudgetSummaryDetail "numéro" budget.reference
                   , viewBudgetSummaryDetail "restant réel" <| String.fromFloat budget.realRemaining
                   , viewBudgetSummaryDetail "restant estimé" <| String.fromFloat budget.virtualRemaining
                   ]
              ]
        , footer [class "card-footer"]
                 [div [ onClick (SelectBudgetClicked budget.id), class "card-footer-item blue-color"] 
                    [ text "voir les opérations"]
                 ]
        ]

viewBudgetSummaryDetail : String -> String -> Html Msg
viewBudgetSummaryDetail label content =
    div [] [ span [class "has-text-weight-semibold"] [text (label ++ ": ")]
           , span [] [text content]
           ]


-- BUDGET VIEW
viewBudget : Model -> Html Msg
viewBudget model =
    div []
        [ h1 [] [ text "Budget page" ]
        ]


-- PAGE NOT FOUND VIEW
viewPageNotFound : Html Msg
viewPageNotFound =
    div []
        [ h1 [] [ text "Not found" ]
        , text "Sorry couldn't find that page"
        ]

-- LOGIN VIEW
viewLogin : Model -> Html Msg
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

module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Url
import Url.Builder
import Url.Parser exposing (Parser, s, map, oneOf, parse, top)
import RemoteData
import Http
import Debug exposing (log)
import Html.Events exposing (onInput, onClick)
import Json.Decode exposing (Decoder, field, string)
import Json.Encode
import Task
import Base64

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
  , page: Page
  , email: String
  , password: String
  , token: String
  , budget: String
  }

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
  ( Model key url LoginPage "claire@superd.net" "pass" "" "", Cmd.none )


-- INTERNAL PAGES 
type Page =
    LoginPage
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
  | ApiPostLoginResponse (RemoteData.WebData String)


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
          { model | url = url
                    , page = toPage url
          }
      in
        ( newModel
        , triggerOnLoadAction newModel
        )
    
    -- LOGIN
    SetEmailInModel email ->
      ({ model | email=email }
      , Cmd.none)
    
    SetPasswordInModel password ->
      ({ model | password=password }
      , Cmd.none)

    LoginButtonClicked ->
      (model
      , apiPostLogin(model))
    
    ApiPostLoginResponse responseToken ->
        case responseToken of
            RemoteData.Success token -> ( { model | token=token }
                                        , Nav.pushUrl model.key "/home")
            _ -> (model, Cmd.none)

    -- HOME
    ApiGetHomeResponse responseBudget ->
        case responseBudget of
            RemoteData.Success budget -> ( { model | budget= (log "budget" budget) }
                                         , Cmd.none)
            _ -> (model, Cmd.none)

triggerOnLoadAction: Model -> Cmd Msg
triggerOnLoadAction model =
  case model.page of
        HomePage ->
            apiGetHome model
        _ ->
            Cmd.none

apiPostLogin: Model -> Cmd Msg
apiPostLogin model =
    postWithBasicAuthorizationHeader model "/login" Http.emptyBody tokenDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiPostLoginResponse

tokenDecoder : Decoder String
tokenDecoder =
  field "token" Json.Decode.string

postWithBasicAuthorizationHeader: Model -> String -> Http.Body -> Decoder String -> Http.Request String
postWithBasicAuthorizationHeader model url body decoder =
  Http.request
    { method = "POST"
    , headers = [ buildBasicAuthorizationHeader model.email model.password ]
    , url = url
    , body = body
    , expect = Http.expectJson tokenDecoder 
    , timeout = Nothing
    , withCredentials = False
    }

buildBasicAuthorizationHeader : String -> String -> Http.Header
buildBasicAuthorizationHeader email password =
    let
        token = Base64.encode (email ++ ":" ++ password)
    in 
        Http.header "Authorization" ("Basic " ++ token)

apiGetHome: Model -> Cmd Msg
apiGetHome model =
  getWithToken model.token "/home" Http.emptyBody budgetSummaryDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiGetHomeResponse

getWithToken: String -> String -> Http.Body -> Decoder String -> Http.Request String
getWithToken token url body decoder =
  Http.request
    { method = "GET"
    , headers = [ buildTokenHeader token ]
    , url = url
    , body = body
    , expect = Http.expectJson budgetSummaryDecoder 
    , timeout = Nothing
    , withCredentials = False
    }

buildTokenHeader : String -> Http.Header
buildTokenHeader token =
    Http.header "token" token

budgetSummaryDecoder : Decoder String
budgetSummaryDecoder =
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
      [ text "The current URL is: "
      , b [] [ text (Url.toString model.url) ]
      , ul []
          [ viewLink "/home"
          , viewLink "/login"
          ]
      ,div []
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
        [ h1 [] [ text "Home Page" ]
        , text <| "budget: " ++ model.budget
        ]


viewPageNotFound : Html Msg
viewPageNotFound =
    div []
        [ h1 [] [ text "Not found" ]
        , text "SOrry couldn't find that page"
        ]

viewLogin : Model -> Html Msg
viewLogin model =
    div [ class "columns" ]
        [ div [ class "column" ] []
        , div [ class "column" ]
            [ h1 [ class "is-size-1 has-text-link has-text-centered has-text-weight-light padding-bottom" ]
                 [ text "la super directrice, c'est toi !" ]
            , viewEmailInput model
            , viewPasswordInput model
            , viewLoginSubmitButton
            ]
        , div [ class "column" ] []
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
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
import Task

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
  }

init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
  ( Model key url LoginPage "" "", Cmd.none )


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
  = LinkClicked Browser.UrlRequest -- Msg qui sera généré par une action user
  | UrlChanged Url.Url -- Msg qui sera généré par le runtime
  | ApiGetHomeResponse (RemoteData.WebData String) -- Msg qui sera généré par le runtime
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
    
    ApiPostLoginResponse token ->
      (model
      , Nav.pushUrl model.key "/home")

    -- HOME
    ApiGetHomeResponse response ->
      (log "model:" model,
      Cmd.none)

triggerOnLoadAction: Model -> Cmd Msg
triggerOnLoadAction model =
  case model.page of
        HomePage ->
            apiGetHome
        _ ->
            Cmd.none

apiPostLogin: Model -> Cmd Msg
apiPostLogin model =
    Http.post "/login" Http.emptyBody tokenDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiPostLoginResponse

tokenDecoder : Decoder String
tokenDecoder =
  field "token" string


apiGetHome: Cmd Msg
apiGetHome =
  Http.getString "/home"
        |> RemoteData.sendRequest
        |> Cmd.map ApiGetHomeResponse



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
        , text "Not implemented yet"
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
            [ input [ class "input", type_ "email", placeholder "Email", value "claire@superd.net", onInput SetEmailInModel ] []
            , span [ class "icon is-small is-left" ] [ i [ class "fas fa-envelope" ] [] ]
            , span [ class "icon is-small is-right" ] [ i [ class "fas fa-check" ] [] ]
            ]
        ]

viewPasswordInput : Model -> Html Msg
viewPasswordInput model =
    div [ class "field" ]
        [ p [ class "control has-icons-left" ]
            [ input [ class "input", type_ "password", placeholder "Password", value "pass", onInput SetPasswordInModel ] []
            , span [ class "icon is-small is-left" ] [ i [ class "fas fa-lock" ] [] ]
            ]
        ]


viewLoginSubmitButton : Html Msg
viewLoginSubmitButton =
    div [ class "has-text-centered" ]
        [ div [ class "button is-info is-rounded", onClick LoginButtonClicked ] [ text "Se connecter" ]
        ] 
module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Url
import Url.Parser exposing (Parser, s, map, oneOf, parse, top)
import RemoteData
import Http
import Debug exposing (log)


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
  }

type Page =
    HomePage
    | NotFoundPage

-- parse l'url pour appeler le bon constructeur de page
pageParser : Parser (Page -> a) a
pageParser =
    oneOf
        [ map HomePage top
        , map HomePage (s "home")
        ]

toPage : Url.Url -> Page
toPage url =
    Maybe.withDefault NotFoundPage (parse pageParser url)


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
  ( Model key url NotFoundPage, Cmd.none )



-- UPDATE
-- explications claires sur le cycle model / view / update
-- et sur les communications runtime <--> model / view / update:
-- https://elmprogramming.com/model-view-update-part-1.html

type Msg
  = LinkClicked Browser.UrlRequest -- Msg qui sera généré par une action user
  | UrlChanged Url.Url -- Msg qui sera généré par le runtime
  | ApiGetHomeResponse (RemoteData.WebData String) -- Msg qui sera généré par le runtime


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    -- 1 -- client clique sur un lien (Msg qui vient de la view)
    LinkClicked urlRequest ->
      case urlRequest of
        Browser.Internal url ->
          -- 2 -- on demande au runtime d'exécuter pushUrl, c'est à dire:
          -- la mise à jour de l'url dans la barre de navigation, 
          -- la mise à jour de l'historique
          -- mais pas de reload de page
          ( model, Nav.pushUrl model.key (Url.toString url) )

        Browser.External href ->
          ( model, Nav.load href )

    -- 3 -- le runtime a changé l'url dans la barre de navigation
    -- et a renvoyé un Msg de type UrlChanged pour indiquer qu'il a fait ce changement
    -- Msg vient du runtime
    UrlChanged url ->
      let
        -- 4 -- update de l'url courante contenue dans la barre de navigation
        -- et update de la page que l'on souhaite loader
        newModel =
          { model | url = url
                    , page = toPage url
          }
      in
        -- 5 -- on donne au runtime le model updaté pour qu'il le passe à la view
        -- on demande au runtime d'exécuter la commande que retournera triggerOnLoadAction
        ( newModel
        , triggerOnLoadAction newModel
        )
    
    -- 8 -- le runtime a envoyé le Msg ApiGetHomeResponse à la fonction update
    -- pour que la suite du traitement soit réalisée
    ApiGetHomeResponse response ->
      (log "model:" model,
      Cmd.none)

-- 6 -- suivant la page à loader
-- cette fonction indique la commande à envoyer au runtime
triggerOnLoadAction: Model -> Cmd Msg
triggerOnLoadAction model =
  case model.page of
        HomePage ->
            apiGetHome
        _ ->
            Cmd.none

-- 7 -- génération de la commande envoyée au runtime pour qu'il l'exécute

-- ApiGetHomeResponse est un constructeur de Msg, sa signature est donc:
-- ApiGetHomeResponse: (Webdata String) -> Msg

-- RemoteData.sendRequest génère une commande destinée au runtime, qui est valide au sein du module RemoteData
-- mais qui n'a pas le bon type pour notre runtime, il faut la caster avec un Cmd.map
-- RemoteData.sendRequest: (Request String) -> Cmd (WebData String)

-- Cast de la Cmd (WebData String) en Cmd.Msg grâce au constructeur ApiGetHomeResponse
-- qui construit un Msg à partir d'un (WebData String)
-- Cmd.map: (a -> msg) -> Cmd a -> Cmd b
-- donne appliqué à notre cas:
-- Cmd.map: ((Webdata String) -> Msg) -> Cmd (WebData String) -> Cmd Msg

-- le runtime exécute la commande et génère un Msg de type ApiGetHomeResponse qu'il envoie à l'update
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
  { title = "URL Interceptor"
  , body =
      [ text "The current URL is: "
      , b [] [ text (Url.toString model.url) ]
      , ul []
          [ viewLink "/home"
          , viewLink "/profile"
          , viewLink "/reviews/the-century-of-the-self"
          , viewLink "/reviews/public-opinion"
          , viewLink "/reviews/shah-of-shahs"
          ]
      ]
  }


viewLink : String -> Html msg
viewLink path =
  li [] [ a [ href path ] [ text path ] ]
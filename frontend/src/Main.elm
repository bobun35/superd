port module Main exposing (..)

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
import Constants exposing (..)
import OperationMuv
import BudgetMuv

-- MAIN


main : Program (Maybe PersistentModel) Model Msg
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
    { key : Maybe Nav.Key
    , url : Url.Url
    , page : Page
    , email : String
    , password : String
    , token : String
    , school : School
    , budgets : List BudgetSummary
    , user : User
    , currentOperation: OperationMuv.Model
    , currentBudget : BudgetMuv.Model
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
    , operations: List OperationMuv.Operation
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

init : (Maybe PersistentModel) -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        emptyModel = 
            Model (Just key) url 
            LoginPage 
            "claire@superd.net" 
            "pass123" 
            "" 
            initSchool 
            initBudgets 
            initUser
            OperationMuv.initModel
            BudgetMuv.initModel
    in
        case flags of
            Just persistentModel ->
                ( { emptyModel | token=persistentModel.token }, Cmd.none )
            Nothing ->
                ( emptyModel
                , Cmd.none )


-- INTERNAL PAGES


type Page
    = LoginPage
    | HomePage
    | BudgetCreatePage
    | BudgetOperationsPage
    | BudgetDetailsPage
    | NotFoundPage


pageParser : Parser (Page -> a) a
pageParser =
    oneOf
        [ map LoginPage top
        , map LoginPage (s "login")
        , map HomePage (s "home")
        , map BudgetOperationsPage (s "budget" </> s "operations")
        , map BudgetDetailsPage (s "budget" </> s "details")
        , map BudgetCreatePage (s "budget")
        ]


toPage : Url.Url -> Page
toPage url =
    Maybe.withDefault NotFoundPage (parse pageParser { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing})

-- PORTS

port setStorage : Json.Encode.Value -> Cmd msg

port removeStorage : Json.Encode.Value -> Cmd msg

setStorageHelper : Model -> Cmd Msg
setStorageHelper model =
    setStorage <| persistentModelToValue <| modelToPersistentModel model


removeStorageHelper : Model -> Cmd Msg
removeStorageHelper model =
    removeStorage <| Json.Encode.string model.token


{-- PersistentModel is used to store only important model values in javascript local storage --}
type alias PersistentModel =
    {
        token: String
    }

modelToPersistentModel: Model -> PersistentModel
modelToPersistentModel model =
    PersistentModel model.token

persistentModelToValue: PersistentModel -> Json.Encode.Value
persistentModelToValue persistentModel =
    Json.Encode.object
    [
        ("token", Json.Encode.string persistentModel.token)
    ]




-- UPDATE

type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | SetEmailInModel String
    | SetPasswordInModel String
    | LoginButtonClicked
    | SelectBudgetClicked Int
    | CreateBudgetClicked
    | GotOperationMsg OperationMuv.Msg
    | GotBudgetMsg BudgetMuv.Msg
    | ApiGetHomeResponse (RemoteData.WebData (List BudgetSummary))
    | ApiPostLoginResponse (RemoteData.WebData LoginResponseData)
    | ApiGetBudgetResponse (RemoteData.WebData BudgetMuv.Budget)
    | ApiPostLogoutResponse (RemoteData.WebData ())
    | ApiPostOrPutOrDeleteOperationResponse (RemoteData.WebData ())
    | LogoutButtonClicked


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        -- ROUTING
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url -> ( model, pushUrl model (Url.toString url) )

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
                    let
                        updatedModel = { model | token = data.token, user = data.user, school = data.school }
                    in
                        ( updatedModel
                        , Cmd.batch[ setStorageHelper updatedModel, pushUrl model (hashed homeUrl)]
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
            , pushUrl model loginUrl )

        -- HOME
        ApiGetHomeResponse response ->
            case response of
                RemoteData.Success budgets ->
                    ( { model | budgets = budgets }
                    , Cmd.none
                    )
                
                RemoteData.Failure httpError -> httpErrorHelper model httpError

                _ ->
                    let
                      _ = log "getHomeHasFailed, model" model   
                    in
                        ( model, Cmd.none )
        
        -- BUDGET
        GotBudgetMsg subMsg ->                
            let
                (subModel, notification, subCmd) = BudgetMuv.update subMsg model.currentBudget
            in
                case notification of
                    
                    BudgetMuv.SendPutRequest budget ->
                        ({ model | currentBudget = subModel }
                        , apiPutBudget model.token subModel )
                    
                    BudgetMuv.SendPostRequest ->
                        ({ model | currentBudget = subModel }
                        , apiPostBudget model.token subModel )

                    BudgetMuv.SendDeleteRequest budget ->
                        ({ model | currentBudget = subModel }
                        , Cmd.none )                    
                    
                    _ -> 
                        ({ model | currentBudget = subModel }
                        , Cmd.map GotBudgetMsg subCmd)
                        
        SelectBudgetClicked budgetId ->
            ( model
            , apiGetBudget model.token budgetId)

        CreateBudgetClicked ->
            let
                createBudgetModel = { model | currentBudget = BudgetMuv.createModel }
            in
                ( createBudgetModel
                , pushUrl createBudgetModel (hashed budgetUrl) )

        ApiGetBudgetResponse responseData ->
            case responseData of
                RemoteData.Success data ->
                    let
                        newSubModel = BudgetMuv.setBudget data model.currentBudget
                        newCmd = if (BudgetMuv.isValid newSubModel)
                                 then pushUrl model (hashed budgetOperationUrl)
                                 else pushUrl model (hashed errorUrl)
                    in
                        ( { model | currentBudget = newSubModel }
                        , newCmd)

                RemoteData.Failure httpError -> httpErrorHelper model httpError
                     
                _ ->
                    let
                      _ = log "getBudgetHasFailed, responseData" responseData   
                    in
                        ( model, Cmd.none )


        -- OPERATION
        GotOperationMsg subMsg ->                
            let
                (subModel, notification, subCmd) = OperationMuv.update subMsg model.currentOperation
                maybeBudgetId = BudgetMuv.getId model.currentBudget
            in
                case (notification, maybeBudgetId) of
                    
                    (OperationMuv.SendPutRequest operation, Just budgetId) ->
                        ({ model | currentOperation = subModel }
                        , apiPutOperation model.token budgetId operation )
                    
                    (OperationMuv.SendPostRequest operation, Just budgetId) ->
                        ({ model | currentOperation = subModel }
                        , apiPostOperation model.token budgetId operation )

                    (OperationMuv.SendDeleteRequest operation, Just budgetId) ->
                        ({ model | currentOperation = subModel }
                        , apiDeleteOperation model.token budgetId operation )
                    
                    _ -> 
                        ({ model | currentOperation = subModel }
                        , Cmd.map GotOperationMsg subCmd)
        
        ApiPostOrPutOrDeleteOperationResponse responseData ->
            case responseData of
                RemoteData.Success _ ->
                    let
                        maybeBudgetId = BudgetMuv.getId model.currentBudget
                    in
                        case maybeBudgetId of
                            Just budgetId -> ( model
                                             ,  Cmd.batch[ apiGetBudget model.token budgetId, apiGetHome model] )
                            Nothing -> ( model, pushUrl model homeUrl)

                RemoteData.Failure httpError -> httpErrorHelper model httpError

                _ ->
                    let
                      _ = log "put or post OperationHasFailed, responseData" responseData   
                    in
                    -- TODO afficher un message de failure pour la modification de l'opération
                      ( model, Cmd.none )


pushUrl: Model -> String -> Cmd Msg
pushUrl model url =
    case model.key of
        Just key -> Nav.pushUrl key url
        Nothing -> Cmd.none

triggerOnLoadAction : Model -> Cmd Msg
triggerOnLoadAction model =
    case model.page of
        HomePage ->
            apiGetHome model
        _ ->
            Cmd.none

httpErrorHelper: Model -> Http.Error -> (Model,  Cmd Msg )
httpErrorHelper model httpError =
    case httpError of
        Http.BadStatus response -> 
            case response.status.code of
                401 -> ( model, pushUrl model homeUrl )
                _ -> ( model, Cmd.none )
        _ -> ( model, Cmd.none )


-- API POST TO LOGIN ENDPOINT

apiPostLogin : Model -> Cmd Msg
apiPostLogin model =
    --postWithBasicAuthorizationHeader model loginUrl Http.emptyBody loginResponseDecoder
    postLoginRequest model loginUrl loginResponseDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiPostLoginResponse

postLoginRequest : Model -> String -> Decoder a -> Http.Request a
postLoginRequest model url decoder =
    let
       body =
          formUrlencoded
             [ ( "email", model.email )
             , ( "password", model.password )
             ]
             |> Http.stringBody "application/x-www-form-urlencoded"
    in
    Http.request
        { method = "POST"
        , headers = []
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }

formUrlencoded : List ( String, String ) -> String
formUrlencoded object =
    object
        |> List.map
            (\( name, value ) ->
                Url.percentEncode name
                    ++ "="
                    ++ Url.percentEncode value
            )
        |> String.join "&"


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


-- API GET BUDGET
apiGetBudget : String -> Int -> Cmd Msg
apiGetBudget token budgetId =
    getWithToken token (budgetUrlWithId budgetId) Http.emptyBody BudgetMuv.budgetDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiGetBudgetResponse

budgetDecoder : Decoder Budget
budgetDecoder =
    Json.Decode.field "budget" budgetDetailDecoder

budgetDetailDecoder: Decoder Budget
budgetDetailDecoder =
    Json.Decode.succeed Budget
        |> Json.Decode.Extra.andMap (Json.Decode.field "id" Json.Decode.int)
        |> Json.Decode.Extra.andMap (Json.Decode.field "name" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.field "reference" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.field "status" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.field "type" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.field "recipient" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.field "creditor" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.Extra.withDefault "" <| Json.Decode.field "comment" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.field "realRemaining" Json.Decode.float)
        |> Json.Decode.Extra.andMap (Json.Decode.field "virtualRemaining" Json.Decode.float)
        |> Json.Decode.Extra.andMap (Json.Decode.field "operations" (Json.Decode.list OperationMuv.operationDecoder))


-- API PUT BUDGET
apiPutBudget : String -> BudgetMuv.Model ->  Cmd Msg
apiPutBudget token budgetModel =
    apiPostorPutBudget "PUT" token budgetModel


-- API POST BUDGET
apiPostBudget : String -> BudgetMuv.Model ->  Cmd Msg
apiPostBudget token budgetModel =
    apiPostorPutBudget "POST" token budgetModel

apiPostorPutBudget : String -> String -> BudgetMuv.Model ->  Cmd Msg
apiPostorPutBudget verb token budgetModel =
    let
        body = Http.jsonBody <| BudgetMuv.budgetEncoder budgetModel
    in
        requestWithTokenEmptyResponseExpected (String.toUpper verb) token budgetUrl body
            |> RemoteData.sendRequest
            |> Cmd.map ApiPostOrPutOrDeleteOperationResponse



-- API PUT OPERATION
apiPutOperation : String -> Int -> OperationMuv.Operation ->  Cmd Msg 
apiPutOperation token budgetId operation =
    apiPostorPutOperation "PUT" token budgetId operation


-- API POST OPERATION
apiPostOperation : String -> Int -> OperationMuv.Operation ->  Cmd Msg 
apiPostOperation token budgetId operation =
    apiPostorPutOperation "POST" token budgetId operation

apiPostorPutOperation : String -> String -> Int -> OperationMuv.Operation ->  Cmd Msg 
apiPostorPutOperation verb token budgetId operation =
    let
        body = Http.jsonBody <| OperationMuv.operationEncoder operation
    in
        requestWithTokenEmptyResponseExpected (String.toUpper verb) token (operationUrl budgetId) body
            |> RemoteData.sendRequest
            |> Cmd.map ApiPostOrPutOrDeleteOperationResponse


-- API DELETE OPERATION
apiDeleteOperation : String -> Int -> OperationMuv.Operation ->  Cmd Msg 
apiDeleteOperation token budgetId operation =
    let
        body = Http.jsonBody <| OperationMuv.idEncoder operation
    in
        requestWithTokenEmptyResponseExpected "DELETE" token (operationUrl budgetId) body
            |> RemoteData.sendRequest
            |> Cmd.map ApiPostOrPutOrDeleteOperationResponse



-- API LOGOUT
apiPostLogout : String -> Cmd Msg
apiPostLogout token =
    requestWithTokenEmptyResponseExpected "POST" token logoutUrl Http.emptyBody
        |> RemoteData.sendRequest
        |> Cmd.map ApiPostLogoutResponse


requestWithTokenEmptyResponseExpected : String -> String -> String -> Http.Body -> Http.Request ()
requestWithTokenEmptyResponseExpected messageType token url body =
    Http.request
        { method = messageType
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

        BudgetCreatePage ->
            viewManageBudget model

        BudgetOperationsPage ->
            viewBudget model OperationsTab

        BudgetDetailsPage ->
            viewBudget model DetailsTab

        NotFoundPage ->
            viewPageNotFound

-- HOME VIEW
viewHome : Model -> Html Msg
viewHome model =
    div [ class "hero is-home-hero is-fullheight"]
        [ viewNavBar model
        , div [class "hero-header"][ div [class "has-text-centered"][viewTitle "les budgets"]]
        , div [class "hero-body is-home-hero-body"] [div [ class "section"]
                                                         [ div [class "container is-fluid"]
                                                               [viewBudgetsPerFamily "fonctionnement" model.budgets]
                                                         ]
                                                    ]
        ]

viewTitle : String -> Html Msg
viewTitle title =
    h1 [class "is-title has-text-centered"] [ text title ]

viewNavBar : Model -> Html Msg
viewNavBar model =
    nav [ class "navbar is-transparent" ]
            [ div [ class "navbar-brand" ]
                  [ div [class "navbar-item"]
                        [ a [class "navbar-item", href "#home"] [text "retour à la liste des budgets"] ]
                  ]
            , div [ class "navbar-menu" ]
                  [ div [class "navbar-end is-hoverable"]
                        [ div [class "navbar-item navbar-user has-dropdown is-hoverable"]
                              [a [class "navbar-link"][text model.user.firstName ]
                              , div [ class "navbar-dropdown is-right is-boxed"]
                                    [ div [class "navbar-item is-hoverable"
                                          , onClick CreateBudgetClicked ] [text "Créer un budget"]
                                    , div [class "navbar-item is-hoverable"
                                          , onClick LogoutButtonClicked] [text "Se déconnecter"]
                                    ]
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
    div [ class "card is-budget-summary"]
        [ header [class "card-header"]
                 [p [class "card-header-title is-centered"][text budget.name]]
        , div [class "card-content" ]
              [div [class "content has-text-left is-budget-summary-content"]
                   [ viewBudgetSummaryDetail "numéro" budget.reference
                   , viewBudgetSummaryDetail "budget disponible" <| String.fromFloat budget.realRemaining
                   , viewBudgetSummaryDetail "budget après engagement" <| String.fromFloat budget.virtualRemaining
                   ]
              ]
        , footer [class "card-footer is-budget-summary-footer", onClick (SelectBudgetClicked budget.id)]
                 [div [ class "card-footer-item blue-color"] 
                    [ text "voir les opérations"]
                 ]
        ]

viewBudgetSummaryDetail : String -> String -> Html Msg
viewBudgetSummaryDetail label content =
    div [] [ span [class "has-text-weight-semibold"] [text (label ++ ": ")]
           , span [] [text content]
           ]


-- BUDGET VIEW

type BudgetTabs 
    = OperationsTab
    | DetailsTab

viewBudget : Model -> BudgetTabs -> Html Msg
viewBudget model tabType =
    if (not <| BudgetMuv.isValid model.currentBudget)
    then viewErrorMessage
    else
        div []
            [ div [ class "hero is-home-hero is-fullheight"]
                  [ viewNavBar model
                  , div [class "hero-header is-budget-hero-header has-text-centered columns"]
                        [ h1 [class "column is-title is-budget-detail-title"] [ text <| Maybe.withDefault "Error"<| BudgetMuv.getName model.currentBudget]
                        , viewBudgetAmounts model.currentBudget
                        ]
                  , div [class "hero-body is-home-hero-body columns is-multiline is-centered"]
                        [ div [ class "column is-budget-tab"]
                              [ div [class "is-fullwidth"] [viewBudgetTabs tabType ]
                              , div [class "is-fullwidth"] [viewTabContent model.currentBudget tabType model.currentOperation ]
                              ]
                        ]
                 ]
            ]

-- affichage des montants sous le titre
viewBudgetAmounts: BudgetMuv.Model -> Html Msg
viewBudgetAmounts budget =
    let
        real =
            amountToStringHelper <| BudgetMuv.getRealRemaining budget
        virtual =
            amountToStringHelper <| BudgetMuv.getVirtualRemaining budget
    in
        div [class "column is-vertical-center"] [ div []
                                                      [ div [class "level"] [text <| "budget disponible: " ++ real]
                                                      , div [class "level"] [text <| "budget après engagement: " ++ virtual]
                                                      ]
                                                ]

amountToStringHelper: Maybe Float -> String
amountToStringHelper amount =
    case amount of
        Nothing -> "unavailable"
        Just value -> String.fromFloat value


-- affichage des onglets
viewBudgetTabs : BudgetTabs -> Html Msg
viewBudgetTabs tabType =
    div [class "tabs is-budget-detail-tab is-centered is-medium is-boxed is-fullwidth is-toggle"]
        [viewTabLinks tabType]

-- mise en avant de l'onglet courant (actif)
viewTabLinks : BudgetTabs -> Html Msg
viewTabLinks tabType =    
    case tabType of
            OperationsTab -> ul [] [viewTabLink True budgetOperationUrl "Opérations" 
                                    , viewTabLink False budgetDetailUrl "Détails" ]
            _ -> ul [] [viewTabLink False budgetOperationUrl "Opérations" 
                       , viewTabLink True budgetDetailUrl "Détails" ]

-- format du titre de l'onglet suivant qu'il est actif ou pas
viewTabLink : Bool -> String -> String -> Html Msg
viewTabLink isActive url tabTitle =
    case isActive of
        True -> li [ class "is-active"] [a [href (hashed url) ] [text tabTitle]]
        _ -> li [] [a [ href (hashed url) ] [text tabTitle]]

-- contenu de l'onglet
viewTabContent : BudgetMuv.Model -> BudgetTabs -> OperationMuv.Model -> Html Msg
viewTabContent budget tabType currentOperation =
    case tabType of
        OperationsTab ->
            let
                operations = BudgetMuv.getOperations budget
            in
                Html.map GotOperationMsg <| OperationMuv.viewOperations operations currentOperation

        DetailsTab -> Html.map GotBudgetMsg <| BudgetMuv.viewInfo budget

viewManageBudget : Model -> Html Msg
viewManageBudget model =
    Html.map GotBudgetMsg <| BudgetMuv.viewModal model.currentBudget


-- PAGE NOT FOUND VIEW
viewPageNotFound : Html Msg
viewPageNotFound =
    div []
        [ h1 [] [ text "Not found" ]
        , text "Sorry couldn't find that page"
        ]

-- ERROR PAGE VIEW
viewErrorMessage : Html Msg
viewErrorMessage =
    div []
        [ h1 [] [ text "Error" ]
        , text "Sorry an unexpected error happened, please contact the adminitrator"
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
            [ input [ class "input is-rounded", type_ "email", placeholder "Email", value model.email, onInput SetEmailInModel ] []
            , span [ class "icon is-small is-left" ] [ i [ class "fas fa-envelope" ] [] ]
            , span [ class "icon is-small is-right" ] [ i [ class "fas fa-check" ] [] ]
            ]
        ]

viewPasswordInput : Model -> Html Msg
viewPasswordInput model =
    div [ class "field" ]
        [ p [ class "control has-icons-left" ]
            [ input [ class "input is-rounded", type_ "password", placeholder "Password", value model.password, onInput SetPasswordInModel ] []
            , span [ class "icon is-small is-left" ] [ i [ class "fas fa-lock" ] [] ]
            ]
        ]

viewLoginSubmitButton : Html Msg
viewLoginSubmitButton =
    div [ class "has-text-centered" ]
        [ div [ class "button is-info is-rounded", onClick LoginButtonClicked ] [ text "Se connecter" ]
        ]

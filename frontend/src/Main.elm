port module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import Constants exposing (..)
import Data.Budget
import Data.Login as Login
import Data.Modal as Modal
import Data.Operation
import Data.School as School
import Data.User as User
import Debug exposing (log)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder)
import Json.Decode.Extra
import Json.Encode
import Pages.Budget
import Pages.Login exposing (FormError)
import Pages.Operation
import RemoteData
import Url
import Url.Parser exposing ((</>), Parser, map, oneOf, parse, s, top)



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
    , formErrors : List FormError
    , token : String
    , school : School.School
    , budgets : List BudgetSummary
    , user : User.User
    , currentOperation : Pages.Operation.Model
    , currentBudget : Data.Budget.Budget
    , modal : Modal.Modal
    , possibleBudgetTypes : List String
    , possibleRecipients : List String
    , possibleCreditors : List String
    }


type alias BudgetSummary =
    { id : Int
    , name : String
    , reference : String
    , budgetType : String
    , recipient : String
    , realRemaining : Float
    , virtualRemaining : Float
    }


initBudgets : List BudgetSummary
initBudgets =
    []


init : Maybe PersistentModel -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        emptyModel =
            { key = Just key
            , url = url
            , page = LoginPage
            , email = "claire@superd.net"
            , password = "pass123"
            , formErrors = []
            , token = ""
            , school = School.init
            , budgets = initBudgets
            , user = User.init
            , currentOperation = Pages.Operation.initModel
            , currentBudget = Data.Budget.init
            , modal = Modal.init
            , possibleBudgetTypes = []
            , possibleRecipients = []
            , possibleCreditors = []
            }
    in
    case flags of
        Just persistentModel ->
            ( { emptyModel | token = persistentModel.token }, Cmd.none )

        Nothing ->
            ( emptyModel
            , Cmd.none
            )



-- ROUTING


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
    Maybe.withDefault NotFoundPage (parse pageParser { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing })



-- PORTS


port setStorage : Json.Encode.Value -> Cmd msg


setStorageHelper : Model -> Cmd Msg
setStorageHelper model =
    model
        |> modelToPersistentModel
        |> persistentModelToValue
        |> setStorage


type alias PersistentModel =
    { token : String
    }


modelToPersistentModel : Model -> PersistentModel
modelToPersistentModel model =
    PersistentModel model.token


persistentModelToValue : PersistentModel -> Json.Encode.Value
persistentModelToValue persistentModel =
    Json.Encode.object
        [ ( "token", Json.Encode.string persistentModel.token )
        ]



-- UPDATE


type Msg
    = ApiGetBudgetResponse (RemoteData.WebData Data.Budget.Budget)
    | ApiGetBudgetTypesResponse (RemoteData.WebData (List String))
    | ApiGetCreditorsResponse (RemoteData.WebData (List String))
    | ApiGetHomeResponse (RemoteData.WebData (List BudgetSummary))
    | ApiGetRecipientsResponse (RemoteData.WebData (List String))
    | ApiPostBudgetResponse (RemoteData.WebData Int)
    | ApiPostLoginResponse (RemoteData.WebData Login.LoginResponseData)
    | ApiPostLogoutResponse (RemoteData.WebData ())
    | ApiPostOrPutOrDeleteOperationResponse (RemoteData.WebData ())
    | CreateBudgetClicked
    | GotBudgetMsg Pages.Budget.Msg
    | GotLoginMsg Pages.Login.Msg
    | GotOperationMsg Pages.Operation.Msg
    | LinkClicked Browser.UrlRequest
    | LogoutButtonClicked
    | SelectBudgetClicked Int
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ApiGetBudgetResponse responseData ->
            case responseData of
                RemoteData.Success data ->
                    let
                        updatedModel =
                            Pages.Budget.setBudget data model

                        cmd =
                            case ( Data.Budget.isValid updatedModel.currentBudget, model.page ) of
                                ( True, BudgetDetailsPage ) ->
                                    pushUrl model (hashed budgetDetailUrl)

                                ( True, _ ) ->
                                    pushUrl model (hashed budgetOperationUrl)

                                ( False, _ ) ->
                                    pushUrl model (hashed errorUrl)
                    in
                    ( updatedModel
                    , cmd
                    )

                RemoteData.Failure httpError ->
                    httpErrorHelper model httpError

                _ ->
                    logAndDoNothing model "getBudget has failed" responseData

        ApiGetBudgetTypesResponse responseData ->
            case responseData of
                RemoteData.Success data ->
                    ( { model | possibleBudgetTypes = data }
                    , Cmd.none
                    )

                RemoteData.Failure httpError ->
                    httpErrorHelper model httpError

                _ ->
                    logAndDoNothing model "getBudgetTypes has failed" responseData

        ApiGetCreditorsResponse responseData ->
            case responseData of
                RemoteData.Success data ->
                    ( { model | possibleCreditors = data }
                    , Cmd.none
                    )

                RemoteData.Failure httpError ->
                    httpErrorHelper model httpError

                _ ->
                    logAndDoNothing model "getCreditors has failed" responseData

        ApiGetRecipientsResponse responseData ->
            case responseData of
                RemoteData.Success data ->
                    ( { model | possibleRecipients = data }
                    , Cmd.none
                    )

                RemoteData.Failure httpError ->
                    httpErrorHelper model httpError

                _ ->
                    logAndDoNothing model "getRecipients has failed" responseData

        ApiGetHomeResponse response ->
            case response of
                RemoteData.Success budgets ->
                    ( { model | budgets = budgets }
                    , Cmd.none
                    )

                RemoteData.Failure httpError ->
                    httpErrorHelper model httpError

                _ ->
                    logAndDoNothing model "get /home has failed" response

        ApiPostBudgetResponse responseData ->
            case responseData of
                RemoteData.Success id ->
                    ( model, pushUrl model (hashed homeUrl) )

                RemoteData.Failure httpError ->
                    httpErrorHelper model httpError

                _ ->
                    logAndDoNothing model "post budget has failed" responseData

        ApiPostLoginResponse responseData ->
            case responseData of
                RemoteData.Success data ->
                    let
                        updatedModel =
                            { model | token = data.token, user = data.user, school = data.school }
                    in
                    ( updatedModel
                    , Cmd.batch
                        [ setStorageHelper updatedModel
                        , pushUrl model (hashed homeUrl)
                        , apiGetBudgetTypes updatedModel.token
                        , apiGetCreditors updatedModel.token
                        , apiGetRecipients updatedModel.token
                        ]
                    )

                _ ->
                    logAndDoNothing model "postLogin has failed" responseData

        ApiPostLogoutResponse _ ->
            ( { model
                | token = ""
                , email = ""
                , password = ""
                , user = User.init
                , school = School.init
                , budgets = initBudgets
              }
            , pushUrl model loginUrl
            )

        ApiPostOrPutOrDeleteOperationResponse responseData ->
            case responseData of
                RemoteData.Success _ ->
                    let
                        maybeBudgetId =
                            Data.Budget.getId model.currentBudget
                    in
                    case maybeBudgetId of
                        Just budgetId ->
                            ( model
                            , Cmd.batch [ apiGetBudget model.token budgetId, apiGetHome model ]
                            )

                        Nothing ->
                            ( model, pushUrl model (hashed homeUrl) )

                RemoteData.Failure httpError ->
                    httpErrorHelper model httpError

                _ ->
                    logAndDoNothing model "post or put or delete operation has failed" responseData

        CreateBudgetClicked ->
            let
                createBudgetModel =
                    Pages.Budget.addNewBudget model
            in
            ( createBudgetModel
            , pushUrl createBudgetModel (hashed budgetUrl)
            )

        GotBudgetMsg budgetMsg ->
            applyBudgetLogic budgetMsg model

        GotLoginMsg loginMsg ->
            applyLoginLogic loginMsg model

        GotOperationMsg operationMsg ->
            applyOperationLogic operationMsg model

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, pushUrl model (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        LogoutButtonClicked ->
            let
                token =
                    model.token
            in
            ( model
            , apiPostLogout token
            )

        SelectBudgetClicked budgetId ->
            ( model
            , apiGetBudget model.token budgetId
            )

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


pushUrl : Model -> String -> Cmd Msg
pushUrl model url =
    case model.key of
        Just key ->
            Nav.pushUrl key url

        Nothing ->
            Cmd.none


triggerOnLoadAction : Model -> Cmd Msg
triggerOnLoadAction model =
    case model.page of
        HomePage ->
            apiGetHome model

        _ ->
            Cmd.none


httpErrorHelper : Model -> Http.Error -> ( Model, Cmd Msg )
httpErrorHelper model httpError =
    case httpError of
        Http.BadStatus response ->
            case response.status.code of
                401 ->
                    ( model, pushUrl model homeUrl )

                _ ->
                    ( model, Cmd.none )

        _ ->
            ( model, Cmd.none )


logAndDoNothing : Model -> String -> a -> ( Model, Cmd Msg )
logAndDoNothing model logLabel dataToLog =
    let
        _ =
            log logLabel dataToLog
    in
    ( model, Cmd.none )



{-----------------------------------------
    COMMUNICATION WITH CUSTOM MODULES
-----------------------------------------}


applyBudgetLogic : Pages.Budget.Msg -> Model -> ( Model, Cmd Msg )
applyBudgetLogic msg model =
    let
        ( updatedModel, notification, subCmd ) =
            Pages.Budget.update msg model
    in
    case notification of
        Pages.Budget.SendPutRequest ->
            ( updatedModel
            , apiPutBudget model.token updatedModel
            )

        Pages.Budget.SendPostRequest ->
            ( updatedModel
            , apiPostBudget model.token updatedModel
            )

        Pages.Budget.SendDeleteRequest ->
            ( updatedModel
            , Cmd.none
            )

        Pages.Budget.ReloadBudget budgetId ->
            ( updatedModel
            , apiGetBudget model.token budgetId
            )

        Pages.Budget.ReloadHome ->
            ( updatedModel
            , pushUrl updatedModel (hashed homeUrl)
            )

        _ ->
            ( updatedModel
            , Cmd.map GotBudgetMsg subCmd
            )


applyLoginLogic : Pages.Login.Msg -> Model -> ( Model, Cmd Msg )
applyLoginLogic msg model =
    let
        ( updatedModel, notification ) =
            Pages.Login.update msg model
    in
    case notification of
        Pages.Login.LoginRequested ->
            ( updatedModel
            , apiPostLogin updatedModel
            )

        Pages.Login.NoNotification ->
            ( updatedModel
            , Cmd.none
            )


applyOperationLogic : Pages.Operation.Msg -> Model -> ( Model, Cmd Msg )
applyOperationLogic msg model =
    let
        ( subModel, notification, subCmd ) =
            Pages.Operation.update msg model.currentOperation

        maybeBudgetId =
            Data.Budget.getId model.currentBudget
    in
    case ( notification, maybeBudgetId ) of
        ( Pages.Operation.SendPutRequest operation, Just budgetId ) ->
            ( { model | currentOperation = subModel }
            , apiPutOperation model.token budgetId operation
            )

        ( Pages.Operation.SendPostRequest operation, Just budgetId ) ->
            ( { model | currentOperation = subModel }
            , apiPostOperation model.token budgetId operation
            )

        ( Pages.Operation.SendDeleteRequest operation, Just budgetId ) ->
            ( { model | currentOperation = subModel }
            , apiDeleteOperation model.token budgetId operation
            )

        _ ->
            ( { model | currentOperation = subModel }
            , Cmd.map GotOperationMsg subCmd
            )



{-----------------------------------------
    SIDE EFFECT: API CALLS
-----------------------------------------}
-- API POST TO LOGIN ENDPOINT


apiPostLogin : Model -> Cmd Msg
apiPostLogin model =
    postLoginRequest model loginUrl Login.loginResponseDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiPostLoginResponse


postLoginRequest : Model -> String -> Decoder a -> Http.Request a
postLoginRequest model url decoder =
    formUrlencoded
        [ ( "email", model.email )
        , ( "password", model.password )
        ]
        |> Http.stringBody "application/x-www-form-urlencoded"
        |> requestWithToken "POST" "" url decoder


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


budgetSummaryDecoder : Decoder BudgetSummary
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
    getWithToken token (budgetUrlWithId budgetId) Http.emptyBody Data.Budget.budgetDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiGetBudgetResponse



-- API PUT BUDGET


apiPutBudget : String -> Model -> Cmd Msg
apiPutBudget token model =
    model.currentBudget
        |> Data.Budget.budgetEncoder
        |> Http.jsonBody
        |> requestWithTokenEmptyResponseExpected "PUT" token budgetUrl
        |> RemoteData.sendRequest
        |> Cmd.map ApiPostOrPutOrDeleteOperationResponse



-- API POST BUDGET


apiPostBudget : String -> Model -> Cmd Msg
apiPostBudget token model =
    model.currentBudget
        |> Data.Budget.budgetEncoder
        |> Http.jsonBody
        |> requestWithToken "POST" token budgetUrl Data.Budget.idDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiPostBudgetResponse



-- API GET BUDGET TYPES


apiGetBudgetTypes : String -> Cmd Msg
apiGetBudgetTypes token =
    getWithToken token budgetTypesUrl Http.emptyBody Data.Budget.itemsDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiGetBudgetTypesResponse



-- API GET CREDITORS TYPES


apiGetCreditors : String -> Cmd Msg
apiGetCreditors token =
    getWithToken token creditorsUrl Http.emptyBody Data.Budget.itemsDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiGetCreditorsResponse



-- API GET CREDITORS TYPES


apiGetRecipients : String -> Cmd Msg
apiGetRecipients token =
    getWithToken token recipientsUrl Http.emptyBody Data.Budget.itemsDecoder
        |> RemoteData.sendRequest
        |> Cmd.map ApiGetRecipientsResponse



-- API PUT OPERATION


apiPutOperation : String -> Int -> Data.Operation.Operation -> Cmd Msg
apiPutOperation token budgetId operation =
    apiPostOrPutOperation "PUT" token budgetId operation



-- API POST OPERATION


apiPostOperation : String -> Int -> Data.Operation.Operation -> Cmd Msg
apiPostOperation token budgetId operation =
    apiPostOrPutOperation "POST" token budgetId operation


apiPostOrPutOperation : String -> String -> Int -> Data.Operation.Operation -> Cmd Msg
apiPostOrPutOperation verb token budgetId operation =
    let
        body =
            Http.jsonBody <| Data.Operation.operationEncoder operation
    in
    requestWithTokenEmptyResponseExpected (String.toUpper verb) token (operationUrl budgetId) body
        |> RemoteData.sendRequest
        |> Cmd.map ApiPostOrPutOrDeleteOperationResponse



-- API DELETE OPERATION


apiDeleteOperation : String -> Int -> Data.Operation.Operation -> Cmd Msg
apiDeleteOperation token budgetId operation =
    operation
        |> Data.Operation.idEncoder
        |> Http.jsonBody
        |> requestWithTokenEmptyResponseExpected "DELETE" token (operationUrl budgetId)
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
    Http.expectStringResponse (\_ -> Ok ())


requestWithToken : String -> String -> String -> Decoder a -> Http.Body -> Http.Request a
requestWithToken method token url decoder body =
    Http.request
        { method = method
        , headers = [ buildTokenHeader token ]
        , url = url
        , body = body
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }



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
            model
                |> Pages.Login.viewLogin
                |> Html.map GotLoginMsg

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
    div [ class "hero is-home-hero is-fullheight" ]
        [ viewNavBar model
        , div [ class "hero-header" ] [ div [ class "has-text-centered" ] [ viewTitle "les budgets" ] ]
        , div [ class "hero-body is-home-hero-body" ]
            [ div [ class "section" ]
                [ div [ class "container is-fluid" ]
                    (List.map (\type_ -> viewPerTypeBudgetSummaries model type_) model.possibleBudgetTypes)
                ]
            ]
        ]


viewPerTypeBudgetSummaries : Model -> String -> Html Msg
viewPerTypeBudgetSummaries model type_ =
    model.budgets
        |> filterBudgetByType type_
        |> viewBudgetSummaries type_


filterBudgetByType : String -> List BudgetSummary -> List BudgetSummary
filterBudgetByType type_ budgets =
    List.filter (\x -> x.budgetType == type_) budgets


viewTitle : String -> Html Msg
viewTitle title =
    h1 [ class "is-title has-text-centered" ] [ text title ]


viewNavBar : Model -> Html Msg
viewNavBar model =
    nav [ class "navbar is-transparent" ]
        [ div [ class "navbar-brand" ]
            [ div [ class "navbar-item" ]
                [ a [ class "navbar-item", href "#home" ] [ text "retour à la liste des budgets" ] ]
            ]
        , div [ class "navbar-menu" ]
            [ div [ class "navbar-end is-hoverable" ]
                [ div [ class "navbar-item navbar-user has-dropdown is-hoverable" ]
                    [ a [ class "navbar-link" ] [ text model.user.firstName ]
                    , div [ class "navbar-dropdown is-right is-boxed" ]
                        [ div
                            [ class "navbar-item is-hoverable"
                            , onClick CreateBudgetClicked
                            ]
                            [ text "Créer un budget" ]
                        , div
                            [ class "navbar-item is-hoverable"
                            , onClick LogoutButtonClicked
                            ]
                            [ text "Se déconnecter" ]
                        ]
                    ]
                ]
            ]
        ]


viewBudgetSummaries : String -> List BudgetSummary -> Html Msg
viewBudgetSummaries type_ budgets =
    if List.isEmpty budgets then
        emptyDiv

    else
        div [ class "container butter-color is-family-container has-text-centered" ]
            [ h2 [ class "is-size-3 has-text-weight-light is-family-container-title" ] [ text type_ ]
            , div [] (List.map viewBudgetSummary budgets)
            ]


emptyDiv : Html Msg
emptyDiv =
    div [] []


viewBudgetSummary : BudgetSummary -> Html Msg
viewBudgetSummary budget =
    div [ class "card is-budget-summary" ]
        [ header [ class "card-header" ]
            [ p [ class "card-header-title is-centered" ] [ text budget.name ] ]
        , div [ class "card-content" ]
            [ div [ class "content has-text-left is-budget-summary-content" ]
                [ viewBudgetSummaryDetail "numéro" budget.reference
                , viewBudgetSummaryDetail "budget disponible" <| String.fromFloat budget.realRemaining
                , viewBudgetSummaryDetail "budget après engagement" <| String.fromFloat budget.virtualRemaining
                ]
            ]
        , footer [ class "card-footer is-budget-summary-footer", onClick (SelectBudgetClicked budget.id) ]
            [ div [ class "card-footer-item blue-color" ]
                [ text "voir les opérations" ]
            ]
        ]


viewBudgetSummaryDetail : String -> String -> Html Msg
viewBudgetSummaryDetail label content =
    div []
        [ span [ class "has-text-weight-semibold" ] [ text (label ++ ": ") ]
        , span [] [ text content ]
        ]



-- BUDGET VIEW


type BudgetTabs
    = OperationsTab
    | DetailsTab


viewBudget : Model -> BudgetTabs -> Html Msg
viewBudget model tabType =
    div []
        [ div [ class "hero is-home-hero is-fullheight" ]
            [ viewNavBar model
            , div [ class "hero-header is-budget-hero-header has-text-centered columns" ]
                [ h1 [ class "column is-title is-budget-detail-title" ]
                    [ Data.Budget.getName model.currentBudget
                        |> Maybe.withDefault "Error"
                        |> text
                    ]
                , viewBudgetAmounts model
                ]
            , div [ class "hero-body is-home-hero-body columns is-multiline is-centered" ]
                [ div [ class "column is-budget-tab" ]
                    [ div [ class "is-fullwidth" ] [ viewBudgetTabs tabType ]
                    , div [ class "is-fullwidth" ] [ viewTabContent model tabType model.currentOperation ]
                    ]
                ]
            ]
        ]


viewBudgetAmounts : Model -> Html Msg
viewBudgetAmounts model =
    let
        real =
            amountToStringHelper <| Data.Budget.getRealRemaining model.currentBudget

        virtual =
            amountToStringHelper <| Data.Budget.getVirtualRemaining model.currentBudget
    in
    div [ class "column is-vertical-center" ]
        [ div []
            [ div [ class "level" ] [ text <| "budget disponible: " ++ real ]
            , div [ class "level" ] [ text <| "budget après engagement: " ++ virtual ]
            ]
        ]


amountToStringHelper : Maybe Float -> String
amountToStringHelper amount =
    case amount of
        Nothing ->
            "unavailable"

        Just value ->
            String.fromFloat value



-- VIEW BUDGET TABS


viewBudgetTabs : BudgetTabs -> Html Msg
viewBudgetTabs tabType =
    div [ class "tabs is-budget-detail-tab is-centered is-medium is-boxed is-fullwidth is-toggle" ]
        [ viewTabLinks tabType ]



-- VIEW THE ACTIVE TAB


viewTabLinks : BudgetTabs -> Html Msg
viewTabLinks tabType =
    case tabType of
        OperationsTab ->
            ul []
                [ viewTabLink True budgetOperationUrl "Opérations"
                , viewTabLink False budgetDetailUrl "Détails"
                ]

        _ ->
            ul []
                [ viewTabLink False budgetOperationUrl "Opérations"
                , viewTabLink True budgetDetailUrl "Détails"
                ]



-- TAB TITLE FORMATTING ACCORDING TO WHETHER IT IS ACTIVE OR NOT


viewTabLink : Bool -> String -> String -> Html Msg
viewTabLink isActive url tabTitle =
    case isActive of
        True ->
            li [ class "is-active" ] [ a [ href (hashed url) ] [ text tabTitle ] ]

        _ ->
            li [] [ a [ href (hashed url) ] [ text tabTitle ] ]



-- VIEW TAB CONTENT


viewTabContent : Model -> BudgetTabs -> Pages.Operation.Model -> Html Msg
viewTabContent model tabType currentOperation =
    case tabType of
        OperationsTab ->
            Data.Budget.getOperations model.currentBudget
                |> Pages.Operation.viewOperations currentOperation
                |> Html.map GotOperationMsg

        DetailsTab ->
            Pages.Budget.viewInfo model
                |> Html.map GotBudgetMsg


viewManageBudget : Model -> Html Msg
viewManageBudget model =
    Pages.Budget.viewModal model
        |> Html.map GotBudgetMsg



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
        , text "Sorry an unexpected error happened, please contact the administrator"
        ]

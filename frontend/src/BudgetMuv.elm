module BudgetMuv exposing
    ( Budget
    , Model
    , Msg
    , Notification(..)
    , budgetDecoder
    , getId
    , getInfo
    , getName
    , getOperations
    , getRealRemaining
    , getValidBudget
    , getVirtualRemaining
    , initModel
    , isValid
    , setBudget
    , update
    , viewInfo
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onBlur, onClick, onInput)
import Json.Decode exposing (Decoder)
import Json.Decode.Extra
import Json.Decode.Pipeline exposing (custom, optional, required)
import Json.Encode
import OperationMuv



{--
This file contains an operation related MUV structure (Model Update View)
The view handles the display of budget details list in a table
and in a modal for creation and modification

Module exposes:
* Budget type, encoder and decoder
* Budget MUV structure: subModel, subMsg, update, notifications and view
--}
{-------------------------
        MODEL
--------------------------}


type alias Model =
    { current : Budget
    , modal : Modal
    }


initModel =
    Model NoBudget NoModal



{-------------------------
        TYPES
--------------------------}


type Budget
    = NoBudget
    | Create Info
    | Validated ExistingBudget
    | Update
        { id : Int
        , info : Info
        }


type alias ExistingBudget =
    { id : Int
    , info : Info
    , realRemaining : Float
    , virtualRemaining : Float
    , operations : List OperationMuv.Operation
    }


isValid : Model -> Bool
isValid model =
    case model.current of
        Validated _ ->
            True

        _ ->
            False



{-------------------------
        getters & setters
    --------------------------}


getValidBudget : Model -> Maybe ExistingBudget
getValidBudget model =
    case model.current of
        Validated existingBudget ->
            Just existingBudget

        _ ->
            Nothing


getId : Model -> Maybe Int
getId model =
    case model.current of
        Validated existingBudget ->
            Just existingBudget.id

        _ ->
            Nothing


getInfo : Model -> Maybe Info
getInfo model =
    case model.current of
        Validated existingBudget ->
            Just existingBudget.info

        _ ->
            Nothing


getRealRemaining : Model -> Maybe Float
getRealRemaining model =
    case model.current of
        Validated existingBudget ->
            Just existingBudget.realRemaining

        _ ->
            Nothing


getVirtualRemaining : Model -> Maybe Float
getVirtualRemaining model =
    case model.current of
        Validated existingBudget ->
            Just existingBudget.virtualRemaining

        _ ->
            Nothing


getOperations : Model -> List OperationMuv.Operation
getOperations model =
    case model.current of
        Validated existingBudget ->
            existingBudget.operations

        _ ->
            []


getName : Model -> Maybe String
getName model =
    case model.current of
        Validated existingBudget ->
            Just existingBudget.info.name

        _ ->
            Nothing


setBudget : Model -> Budget -> Model
setBudget model budget =
    { model | current = budget }



{--private types --}


type alias Info =
    { name : String
    , reference : String
    , status : String
    , budgetType : String
    , recipient : String
    , creditor : String
    , comment : String
    }


emptyInfo =
    Info "" "" "" "" "" "" ""


type Modal
    = NoModal
    | ReadOnlyModal
    | ModifyModal
    | CreateModal



{-------------------------
        UPDATE
--------------------------}


type Notification
    = NoNotification
    | SendPostRequest Budget
    | SendPutRequest Budget
    | SendDeleteRequest Budget


type Msg
    = CloseModalClicked
    | ModifyClicked
    | SaveClicked
    | AddClicked
    | SetName String


update : Msg -> Model -> ( Model, Notification, Cmd Msg )
update msg model =
    case msg of
        CloseModalClicked ->
            ( { model | modal = NoModal, current = NoBudget }
            , NoNotification
            , Cmd.none
            )

        ModifyClicked ->
            ( { model | modal = ModifyModal }
            , NoNotification
            , Cmd.none
            )

        SaveClicked ->
            case model.current of
                Validated existingBudget ->
                    let
                        updatedBudget =
                            Update { id = existingBudget.id, info = existingBudget.info }
                    in
                    ( { model | modal = NoModal, current = NoBudget }
                    , SendPutRequest updatedBudget
                    , Cmd.none
                    )

                Create content ->
                    ( { model | modal = NoModal, current = NoBudget }
                    , SendPostRequest (Create content)
                    , Cmd.none
                    )

                _ ->
                    ( { model | modal = NoModal, current = NoBudget }
                    , NoNotification
                    , Cmd.none
                    )

        AddClicked ->
            ( { model | modal = CreateModal, current = Create emptyInfo }
            , NoNotification
            , Cmd.none
            )

        SetName value ->
            case model.current of
                Validated existingBudget ->
                    let
                        oldInfo =
                            existingBudget.info

                        newInfo =
                            { oldInfo | name = value }
                    in
                    ( { model
                        | current =
                            Validated
                                { id = existingBudget.id
                                , info = newInfo
                                , realRemaining = existingBudget.realRemaining
                                , virtualRemaining = existingBudget.virtualRemaining
                                , operations = existingBudget.operations
                                }
                      }
                    , NoNotification
                    , Cmd.none
                    )

                Create info ->
                    let
                        newInfo =
                            { info | name = value }
                    in
                    ( { model | current = Create newInfo }
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )



{-------------------------
        DECODER
--------------------------}


budgetDecoder : Decoder Budget
budgetDecoder =
    Json.Decode.field "budget" budgetDetailDecoder


budgetDetailDecoder : Decoder Budget
budgetDetailDecoder =
    Json.Decode.succeed toDecoder
        |> Json.Decode.Pipeline.required "id" Json.Decode.int
        |> Json.Decode.Pipeline.required "name" Json.Decode.string
        |> Json.Decode.Pipeline.required "reference" Json.Decode.string
        |> Json.Decode.Pipeline.required "status" Json.Decode.string
        |> Json.Decode.Pipeline.required "type" Json.Decode.string
        |> Json.Decode.Pipeline.required "recipient" Json.Decode.string
        |> Json.Decode.Pipeline.required "creditor" Json.Decode.string
        |> Json.Decode.Pipeline.required "comment" (Json.Decode.Extra.withDefault "" Json.Decode.string)
        |> Json.Decode.Pipeline.required "realRemaining" Json.Decode.float
        |> Json.Decode.Pipeline.required "virtualRemaining" Json.Decode.float
        |> Json.Decode.Pipeline.required "operations" (Json.Decode.list OperationMuv.operationDecoder)
        |> Json.Decode.Pipeline.resolve


toDecoder : Int -> String -> String -> String -> String -> String -> String -> String -> Float -> Float -> List OperationMuv.Operation -> Decoder Budget
toDecoder id name reference status budgetType recipient creditor comment real virtual operations =
    ExistingBudget id
                    (Info name reference status budgetType recipient creditor comment)
                    real
                    virtual
                    operations
        |> Validated
        |> Json.Decode.succeed


{-------------------------
        ENCODER
--------------------------}
{-------------------------
        VIEW
--------------------------}


viewInfo : Model -> Html Msg
viewInfo model =
    case model.current of
        Validated existingBudget ->
            table [ class "table is-budget-tab-content is-striped is-hoverable is-fullwidth" ]
                [ viewInfoRows existingBudget.info ]
        _ -> text "Error, this budget is not a valid"


viewInfoRows : Info -> Html Msg
viewInfoRows info =
    tbody []
        [ viewInfoRow "famille du budget" info.budgetType
        , viewInfoRow "référence comptable" info.reference
        , viewInfoRow "type du budget" info.creditor
        , viewInfoRow "bénéficiaire" info.recipient
        , viewInfoRow "commentaires" info.comment
        ]


viewInfoRow : String -> String -> Html Msg
viewInfoRow label value =
    tr []
        [ th [] [ text label ]
        , td [] [ text value ]
        ]

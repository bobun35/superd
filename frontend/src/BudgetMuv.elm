module BudgetMuv exposing
    ( Budget
    , Model
    , Msg
    , Notification(..)
    , budgetDecoder
    , budgetEncoder
    , budgetTypesDecoder
    , getId
    , getInfo
    , getName
    , getOperations
    , getRealRemaining
    , getVirtualRemaining
    , initCreateModal
    , initModel
    , isUpdate
    , isValid
    , setBudget
    , setBudgetTypes
    , update
    , viewInfo
    , viewModal
    )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onInput, targetValue)
import Json.Decode exposing (Decoder)
import Json.Decode.Extra
import Json.Decode.Pipeline
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
    , possibleBudgetTypes : List String
    }


initModel =
    Model NoBudget NoModal []


initCreateModal : Model -> Model
initCreateModal model =
    Model (Create (defaultInfo model)) CreateModal model.possibleBudgetTypes



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


isUpdate : Model -> Bool
isUpdate model =
    case model.current of
        Update _ ->
            True

        _ ->
            False



{-------------------------
        getters & setters
    --------------------------}


getId : Model -> Maybe Int
getId model =
    case model.current of
        Validated existingBudget ->
            Just existingBudget.id

        Update updatedBudget ->
            Just updatedBudget.id

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


setBudget : Budget -> Model -> Model
setBudget budget model =
    { model | current = budget }


asCurrentBudgetIn : Model -> Budget -> Model
asCurrentBudgetIn model budget =
    setBudget budget model


asInfoIn : Budget -> Info -> Budget
asInfoIn budget newInfo =
    case budget of
        Validated existingBudget ->
            Validated { existingBudget | info = newInfo }

        Create info ->
            Create newInfo

        _ ->
            budget



{--private types --}


type alias Info =
    { name : String
    , reference : String
    , budgetType : String
    , recipient : String
    , creditor : String
    , comment : String
    }


setInfoName : String -> Info -> Info
setInfoName newName info =
    { info | name = newName }


asNameIn : Info -> String -> Info
asNameIn info newName =
    setInfoName newName info


setReference : String -> Info -> Info
setReference newReference info =
    { info | reference = newReference }


asReferenceIn : Info -> String -> Info
asReferenceIn info newReference =
    setReference newReference info


setBudgetType : String -> Info -> Info
setBudgetType newBudgetType info =
    { info | budgetType = newBudgetType }


asBudgetTypeIn : Info -> String -> Info
asBudgetTypeIn info newBudgetType =
    setBudgetType newBudgetType info


setBudgetTypes : Model -> List String -> Model
setBudgetTypes model newBudgetTypes =
    { model | possibleBudgetTypes = newBudgetTypes }


setRecipient : String -> Info -> Info
setRecipient newRecipient info =
    { info | recipient = newRecipient }


asRecipientIn : Info -> String -> Info
asRecipientIn info newRecipient =
    setRecipient newRecipient info


setCreditor : String -> Info -> Info
setCreditor newCreditor info =
    { info | creditor = newCreditor }


asCreditorIn : Info -> String -> Info
asCreditorIn info newCreditor =
    setCreditor newCreditor info


setComment : String -> Info -> Info
setComment newComment info =
    { info | comment = newComment }


asCommentIn : Info -> String -> Info
asCommentIn info newComment =
    setComment newComment info


defaultInfo : Model -> Info
defaultInfo model =
    let
        defaultBudgetType =
            Maybe.withDefault "" <| List.head model.possibleBudgetTypes
    in
    { name = ""
    , reference = ""
    , budgetType = defaultBudgetType
    , recipient = ""
    , creditor = ""
    , comment = ""
    }


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
    | GetBudgetTypes
    | SendPostRequest
    | SendPutRequest
    | SendDeleteRequest
    | ReloadBudget Int
    | ReloadHome


type Msg
    = AddClicked
    | BudgetTypeSelected String
    | CloseModalClicked
    | ModifyClicked
    | SaveClicked
    | SetComment String
    | SetCreditor String
    | SetName String
    | SetRecipient String
    | SetReference String


update : Msg -> Model -> ( Model, Notification, Cmd Msg )
update msg model =
    case msg of
        BudgetTypeSelected newType ->
            case model.current of
                Validated existingBudget ->
                    ( newType
                        |> asBudgetTypeIn existingBudget.info
                        |> asInfoIn model.current
                        |> asCurrentBudgetIn model
                    , NoNotification
                    , Cmd.none
                    )

                Create info ->
                    ( newType
                        |> asBudgetTypeIn info
                        |> asInfoIn model.current
                        |> asCurrentBudgetIn model
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        CloseModalClicked ->
            case model.current of
                Validated existingBudget ->
                    ( { model | modal = NoModal }
                    , ReloadBudget existingBudget.id
                    , Cmd.none
                    )

                Create info ->
                    ( { model | modal = NoModal }
                    , ReloadHome
                    , Cmd.none
                    )

                _ ->
                    ( { model | modal = NoModal }
                    , NoNotification
                    , Cmd.none
                    )

        ModifyClicked ->
            ( { model | modal = ModifyModal }
            , GetBudgetTypes
            , Cmd.none
            )

        SaveClicked ->
            case model.current of
                Validated existingBudget ->
                    let
                        updatedBudget =
                            Update { id = existingBudget.id, info = existingBudget.info }
                    in
                    ( { model | modal = NoModal, current = updatedBudget }
                    , SendPutRequest
                    , Cmd.none
                    )

                Create info ->
                    ( { model | modal = NoModal }
                    , SendPostRequest
                    , Cmd.none
                    )

                _ ->
                    ( { model | modal = NoModal, current = NoBudget }
                    , NoNotification
                    , Cmd.none
                    )

        AddClicked ->
            ( { model | modal = CreateModal, current = Create (defaultInfo model) }
            , NoNotification
            , Cmd.none
            )

        SetName newName ->
            case model.current of
                Validated existingBudget ->
                    ( newName
                        |> asNameIn existingBudget.info
                        |> asInfoIn model.current
                        |> asCurrentBudgetIn model
                    , NoNotification
                    , Cmd.none
                    )

                Create info ->
                    ( newName
                        |> asNameIn info
                        |> asInfoIn model.current
                        |> asCurrentBudgetIn model
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        SetReference newReference ->
            case model.current of
                Validated existingBudget ->
                    ( newReference
                        |> asReferenceIn existingBudget.info
                        |> asInfoIn model.current
                        |> asCurrentBudgetIn model
                    , NoNotification
                    , Cmd.none
                    )

                Create info ->
                    ( newReference
                        |> asReferenceIn info
                        |> asInfoIn model.current
                        |> asCurrentBudgetIn model
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        SetRecipient newRecipient ->
            case model.current of
                Validated existingBudget ->
                    ( newRecipient
                        |> asRecipientIn existingBudget.info
                        |> asInfoIn model.current
                        |> asCurrentBudgetIn model
                    , NoNotification
                    , Cmd.none
                    )

                Create info ->
                    ( newRecipient
                        |> asRecipientIn info
                        |> asInfoIn model.current
                        |> asCurrentBudgetIn model
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        SetCreditor newCreditor ->
            case model.current of
                Validated existingBudget ->
                    ( newCreditor
                        |> asCreditorIn existingBudget.info
                        |> asInfoIn model.current
                        |> asCurrentBudgetIn model
                    , NoNotification
                    , Cmd.none
                    )

                Create info ->
                    ( newCreditor
                        |> asCreditorIn info
                        |> asInfoIn model.current
                        |> asCurrentBudgetIn model
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        SetComment newComment ->
            case model.current of
                Validated existingBudget ->
                    ( newComment
                        |> asCommentIn existingBudget.info
                        |> asInfoIn model.current
                        |> asCurrentBudgetIn model
                    , NoNotification
                    , Cmd.none
                    )

                Create info ->
                    ( newComment
                        |> asCommentIn info
                        |> asInfoIn model.current
                        |> asCurrentBudgetIn model
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
        |> Json.Decode.Pipeline.required "type" Json.Decode.string
        |> Json.Decode.Pipeline.required "recipient" Json.Decode.string
        |> Json.Decode.Pipeline.required "creditor" Json.Decode.string
        |> Json.Decode.Pipeline.required "comment" (Json.Decode.Extra.withDefault "" Json.Decode.string)
        |> Json.Decode.Pipeline.required "realRemaining" Json.Decode.float
        |> Json.Decode.Pipeline.required "virtualRemaining" Json.Decode.float
        |> Json.Decode.Pipeline.required "operations" (Json.Decode.list OperationMuv.operationDecoder)
        |> Json.Decode.Pipeline.resolve


toDecoder : Int -> String -> String -> String -> String -> String -> String -> Float -> Float -> List OperationMuv.Operation -> Decoder Budget
toDecoder id name reference budgetType recipient creditor comment real virtual operations =
    ExistingBudget id
        (Info name reference budgetType recipient creditor comment)
        real
        virtual
        operations
        |> Validated
        |> Json.Decode.succeed


budgetTypesDecoder : Decoder (List String)
budgetTypesDecoder =
    Json.Decode.field "types" (Json.Decode.list budgetTypeDecoder)


budgetTypeDecoder : Decoder String
budgetTypeDecoder =
    Json.Decode.field "name" Json.Decode.string



{-------------------------
        ENCODER
--------------------------}


budgetEncoder : Model -> Json.Encode.Value
budgetEncoder model =
    case model.current of
        Update updatedBudget ->
            Json.Encode.object
                [ ( "id", Json.Encode.int updatedBudget.id )
                , ( "name", Json.Encode.string updatedBudget.info.name )
                , ( "reference", Json.Encode.string updatedBudget.info.reference )
                , ( "budgetType", Json.Encode.string updatedBudget.info.budgetType )
                , ( "recipient", Json.Encode.string updatedBudget.info.recipient )
                , ( "creditor", Json.Encode.string updatedBudget.info.creditor )
                , ( "comment", Json.Encode.string updatedBudget.info.comment )
                ]

        Create info ->
            Json.Encode.object
                [ ( "name", Json.Encode.string info.name )
                , ( "reference", Json.Encode.string info.reference )
                , ( "budgetType", Json.Encode.string info.budgetType )
                , ( "recipient", Json.Encode.string info.recipient )
                , ( "creditor", Json.Encode.string info.creditor )
                , ( "comment", Json.Encode.string info.comment )
                ]

        _ ->
            Json.Encode.null



{-------------------------
        VIEW
--------------------------}


viewInfo : Model -> Html Msg
viewInfo model =
    case model.current of
        Validated existingBudget ->
            div []
                [ viewModifyButton
                , table [ class "table is-budget-tab-content is-striped is-hoverable is-fullwidth" ]
                    [ viewInfoRows existingBudget.info ]
                , viewModal model
                ]

        _ ->
            text "Error, this budget is not a valid"


viewModifyButton : Html Msg
viewModifyButton =
    button [ class "button is-rounded is-hovered is-pulled-right is-plus-button", onClick ModifyClicked ]
        [ span [ class "icon is-small" ]
            [ i [ class "fas fa-pencil-alt" ] [] ]
        ]


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



-- MODAL


viewModal : Model -> Html Msg
viewModal model =
    case ( model.modal, model.current ) of
        ( NoModal, _ ) ->
            emptyDiv

        ( _, Validated existingBudget ) ->
            displayModal model (Just existingBudget.id) existingBudget.info ModifyModal

        ( CreateModal, Create info ) ->
            displayModal model Nothing info CreateModal

        ( _, _ ) ->
            emptyDiv


emptyDiv : Html Msg
emptyDiv =
    div [] []


displayModal : Model -> Maybe Int -> Info -> Modal -> Html Msg
displayModal model maybeId info modal =
    div [ class "modal is-operation-modal" ]
        [ div [ class "modal-background" ] []
        , div [ class "modal-card" ]
            [ header [ class "modal-card-head" ]
                (viewModalHeader info)
            , section [ class "modal-card-body" ]
                [ table [ class "table is-budget-tab-content is-striped is-hoverable is-fullwidth" ]
                    [ viewModalBody model info modal ]
                ]
            , footer [ class "modal-card-foot" ]
                viewModalFooter
            ]
        ]


viewModalHeader : Info -> List (Html Msg)
viewModalHeader info =
    [ p [ class "modal-card-title" ] [ text info.name ] ]


viewModalBody : Model -> Info -> Modal -> Html Msg
viewModalBody model info modal =
    case modal of
        ModifyModal ->
            viewFields model info viewInputFormat

        CreateModal ->
            viewFields model info viewInputFormat

        _ ->
            emptyDiv


viewFields : Model -> Info -> ((String -> Msg) -> String -> Html Msg) -> Html Msg
viewFields model info callback =
    tbody []
        [ tr []
            [ viewLabel "nom"
            , callback SetName info.name
            ]
        , tr []
            [ viewLabel "référence"
            , callback SetReference info.reference
            ]
        , tr []
            [ viewLabel "type"
            , viewSelectType model BudgetTypeSelected info.budgetType
            ]
        , tr []
            [ viewLabel "bénéficiaire"
            , callback SetRecipient info.recipient
            ]
        , tr []
            [ viewLabel "créditeur"
            , callback SetCreditor info.creditor
            ]
        , tr []
            [ viewLabel "commentaire"
            , callback SetComment info.comment
            ]
        ]


viewLabel : String -> Html Msg
viewLabel label =
    th [] [ text label ]


viewInputFormat : (String -> Msg) -> String -> Html Msg
viewInputFormat msg val =
    td [] [ input [ type_ "text", value val, onInput msg ] [] ]


viewSelectType : Model -> (String -> Msg) -> String -> Html Msg
viewSelectType model msg currentValue =
    div [ class "select" ]
        [ select [ on "change" (Json.Decode.map msg targetValue) ]
            (List.map
                (\x ->
                    if x == currentValue then
                        selectedTypeOption x

                    else
                        typeOption x
                )
                model.possibleBudgetTypes
            )
        ]


selectedTypeOption : String -> Html Msg
selectedTypeOption type_ =
    option [ value type_, selected True ] [ text type_ ]


typeOption : String -> Html Msg
typeOption type_ =
    option [ value type_ ] [ text type_ ]


viewModalFooter : List (Html Msg)
viewModalFooter =
    modalSaveAndCancelButtons


modalSaveAndCancelButtons : List (Html Msg)
modalSaveAndCancelButtons =
    [ successButton "Enregistrer" SaveClicked
    , cancelButton "Annuler" CloseModalClicked
    ]


successButton : String -> Msg -> Html Msg
successButton label actionOnClick =
    div [ class "button is-success", onClick actionOnClick ]
        [ span [ class "icon is-small" ]
            [ i [ class "fas fa-check" ] []
            ]
        , span [] [ text label ]
        ]


cancelButton : String -> Msg -> Html Msg
cancelButton label actionOnClick =
    div [ class "button is-info  is-outlined", onClick actionOnClick ]
        [ span [] [ text label ]
        ]

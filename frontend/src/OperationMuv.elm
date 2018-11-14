module OperationMuv exposing (Operation, Msg, Model, update, initModel, operationDecoder, viewOperations)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onBlur)
import Json.Decode exposing (Decoder)
import Json.Decode.Extra


{--
This file contains an operation related MUV structure (Model Update View)
The view handles the display of operation list in a table
and of single operation in a modal

Module exposes:
* Operation type and decoder for use in Budget type
* Operation subModel, subMsg, update and view
--}



{-------------------------
        MODEL
--------------------------}
type alias Model =
    { content: OperationStatus 
    , modal: Modal }

initModel =
    Model NoOperation NoModal



{-------------------------
        TYPES
--------------------------}

type alias Operation =
    { id: Int
    , name: String
    , operationType: OperationType
    , store: String
    , comment: Maybe String
    , quotation: Quotation
    , invoice: Invoice
    }

-- private types
type OperationStatus
    = NoOperation
    | IdOnly Int
    | Validated Operation

type OperationType 
    = Credit
    | Debit

type alias Quotation =
    { quotationReference: Maybe String
    , quotationDate: Maybe String
    , quotationAmount: AmountField
    }

-- allows to use number in input field
type alias AmountField = 
    { value: Maybe Float
    , stringValue: String
    }
    

type alias Invoice =
    { invoiceReference: Maybe String
    , invoiceDate: Maybe String
    , invoiceAmount: AmountField
    }

type Modal 
    = NoModal
    | DisplayOperationModal
    | ModifyOperationModal
    | CreateOperationModal




{-------------------------
        UPDATE
--------------------------}

type Msg
    = SelectOperationClicked Int
    | CloseOperationModalClicked
    | ModifyOperationClicked Operation
    | SetName String
    | SetQuotationReference String
    | SetQuotationDate String
    | SetQuotationAmount String
    | SetInvoiceReference String
    | SetInvoiceDate String
    | SetInvoiceAmount String
    | SetStore String
    | SetComment String

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectOperationClicked operationId ->
            ( { model | modal = DisplayOperationModal, content = IdOnly operationId }
            , Cmd.none )
        
        CloseOperationModalClicked ->
            ( { model | modal = NoModal, content = NoOperation }
            , Cmd.none)
        
        ModifyOperationClicked operation ->
            ( { model | modal = ModifyOperationModal, content = Validated operation }
            , Cmd.none )

        SetName value ->
            case model.content of
                Validated operation -> let 
                                            newContent = { operation | name = value} 
                                        in
                                            ( { model | content = Validated newContent }, Cmd.none)
                _ -> (model, Cmd.none)

        SetQuotationReference value ->
            case model.content of
                Validated operation -> let 
                                            oldQuotation = operation.quotation
                                            newQuotation = { oldQuotation | quotationReference = Just value }
                                            newContent = { operation | quotation = newQuotation } 
                                        in
                                            ( { model | content = Validated newContent }, Cmd.none)
                _ -> (model, Cmd.none)

        SetQuotationDate value ->
            case model.content of
                Validated operation -> let 
                                            oldQuotation = operation.quotation
                                            newQuotation = { oldQuotation | quotationDate = Just value }
                                            newContent = { operation | quotation = newQuotation } 
                                        in
                                            ( { model | content = Validated newContent }, Cmd.none)
                _ -> (model, Cmd.none)

        SetQuotationAmount value ->
            case model.content of
                Validated operation -> 
                    case (String.toFloat value) of
                        Just amount -> let 
                                            oldQuotation = operation.quotation
                                            newQuotation = { oldQuotation | quotationAmount = AmountField (Just amount) value }
                                            newContent = { operation | quotation = newQuotation } 
                                        in
                                            ( { model | content = Validated newContent }, Cmd.none)
                        Nothing -> let 
                                        oldQuotation = operation.quotation
                                        newQuotation = { oldQuotation | quotationAmount = AmountField Nothing value }
                                        newContent = { operation | quotation = newQuotation } 
                                    in
                                        ( { model | content = Validated newContent }, Cmd.none)
                _ -> (model, Cmd.none)

        SetInvoiceReference value ->
            case model.content of
                Validated operation -> let 
                                            oldInvoice = operation.invoice
                                            newInvoice = { oldInvoice | invoiceReference = Just value }
                                            newContent = { operation | invoice = newInvoice } 
                                        in
                                            ( { model | content = Validated newContent }, Cmd.none)
                _ -> (model, Cmd.none)

        SetInvoiceDate value ->
            case model.content of
                Validated operation -> let 
                                            oldInvoice = operation.invoice
                                            newInvoice = { oldInvoice | invoiceDate = Just value }
                                            newContent = { operation | invoice = newInvoice } 
                                        in
                                            ( { model | content = Validated newContent }, Cmd.none)
                _ -> (model, Cmd.none)

        SetInvoiceAmount value ->
            case model.content of
                Validated operation -> 
                    case (String.toFloat value) of
                        Just amount -> let 
                                            oldInvoice = operation.invoice
                                            newInvoice = { oldInvoice | invoiceAmount = AmountField (Just amount) value }
                                            newContent = { operation | invoice = newInvoice } 
                                        in
                                            ( { model | content = Validated newContent }, Cmd.none)
                        Nothing -> let 
                                        oldInvoice = operation.invoice
                                        newInvoice = { oldInvoice | invoiceAmount = AmountField Nothing value }
                                        newContent = { operation | invoice = newInvoice } 
                                    in
                                        ( { model | content = Validated newContent }, Cmd.none)
                _ -> (model, Cmd.none)

        SetStore value ->
            case model.content of
                Validated operation -> let 
                                            newContent = { operation | store = value} 
                                        in
                                            ( { model | content = Validated newContent }, Cmd.none)
                _ -> (model, Cmd.none)

        SetComment value ->
            case model.content of
                Validated operation -> let 
                                            newContent = { operation | comment = Just value } 
                                        in
                                            ( { model | content = Validated newContent }, Cmd.none)
                _ -> (model, Cmd.none)


{-------------------------
        DECODER
--------------------------}
operationDecoder: Decoder Operation
operationDecoder =
    Json.Decode.succeed Operation
        |> Json.Decode.Extra.andMap (Json.Decode.field "id" Json.Decode.int)
        |> Json.Decode.Extra.andMap (Json.Decode.field "name" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.field "type" operationTypeDecoder)
        |> Json.Decode.Extra.andMap (Json.Decode.field "store" Json.Decode.string)
        |> Json.Decode.Extra.andMap (Json.Decode.field "comment" (Json.Decode.nullable Json.Decode.string))
        |> Json.Decode.Extra.andMap (Json.Decode.map3 Quotation 
                (Json.Decode.field "quotation" (Json.Decode.nullable Json.Decode.string)) 
                (Json.Decode.field "quotationDate" (Json.Decode.nullable dateDecoder)) 
                (Json.Decode.field "quotationAmount" amountDecoder))
        |> Json.Decode.Extra.andMap (Json.Decode.map3 Invoice 
                (Json.Decode.field "invoice" (Json.Decode.nullable Json.Decode.string)) 
                (Json.Decode.field "invoiceDate" (Json.Decode.nullable dateDecoder))
                (Json.Decode.field "invoiceAmount" amountDecoder))

operationTypeDecoder: Decoder OperationType
operationTypeDecoder =
    Json.Decode.string
        |> Json.Decode.andThen operationTypeStringDecoder

operationTypeStringDecoder: String -> Decoder OperationType
operationTypeStringDecoder typeString =
    case String.toLower(typeString) of
        "credit" -> Json.Decode.succeed Credit
        "debit" -> Json.Decode.succeed Debit
        _ -> Json.Decode.fail ("Error while decoding operationType: " ++ typeString)

dateDecoder: Decoder String
dateDecoder =
    Json.Decode.succeed toDateString
        |> Json.Decode.Extra.andMap (Json.Decode.field "dayOfMonth" Json.Decode.int)
        |> Json.Decode.Extra.andMap (Json.Decode.field "monthOfYear" Json.Decode.int)
        |> Json.Decode.Extra.andMap (Json.Decode.field "yearOfEra" Json.Decode.int)

toDateString : Int -> Int -> Int -> String
toDateString day month year =
    String.join "/" [ String.fromInt(day)
                    , String.fromInt(month)
                    , String.fromInt(year)]

amountDecoder : Decoder AmountField
amountDecoder =
    Json.Decode.nullable Json.Decode.int
        |> Json.Decode.andThen amountFieldDecoder

amountFieldDecoder : Maybe Int -> Decoder AmountField
amountFieldDecoder maybeAmount =
    case (centsToEuros maybeAmount) of
        Just amount -> Json.Decode.succeed <| AmountField (Just amount) (String.fromFloat amount)
        Nothing -> Json.Decode.succeed <| AmountField Nothing ""


{-------------------------
        VIEW
--------------------------}

-- VIEW ALL OPERATIONS IN A TABLE
viewOperations: List Operation -> Model -> Html Msg
viewOperations operations operationModel =
    div [] [table [ class "table is-budget-tab-content is-striped is-hoverable is-fullwidth"]
                  [ viewOperationsHeaderRow 
                  , viewOperationsRows operations ]
            , viewOperationModal operations operationModel ]

viewOperationsHeaderRow: Html Msg
viewOperationsHeaderRow =
    let
        columnNames = [ "nom"
                      , "n° devis"
                      , "date devis"
                      , "montant devis"
                      , "n° facture"
                      , "date facture"
                      , "montant facture"
                      , "fournisseur"
                      , "commentaire"
                      ]
    in
        thead [] [ tr [] (List.map viewOperationsHeaderCell columnNames)]

viewOperationsHeaderCell: String -> Html Msg
viewOperationsHeaderCell cellContent =
    th [] [text cellContent]

viewOperationsRows: List Operation -> Html Msg
viewOperationsRows operations =
    tbody [] (List.map viewOperationsRow operations)

viewOperationsRow: Operation -> Html Msg
viewOperationsRow operation =
        tr [ onClick <| SelectOperationClicked operation.id ] [ th [] [text operation.name]
                , td [] [text <| Maybe.withDefault "" operation.quotation.quotationReference ]
                , td [] [text <| Maybe.withDefault "" operation.quotation.quotationDate ]
                , td [] [text <| operation.quotation.quotationAmount.stringValue ]
                , td [] [text <| Maybe.withDefault "" operation.invoice.invoiceReference ]
                , td [] [text <| Maybe.withDefault "" operation.invoice.invoiceDate ]
                , td [] [text operation.invoice.invoiceAmount.stringValue ]
                , td [] [text operation.store ]
                , td [] [text <| Maybe.withDefault "" operation.comment ]
            ]

centsToEuros: Maybe Int -> Maybe Float
centsToEuros maybeAmount =
    case maybeAmount of
        Just amount -> Just (toFloat amount / 100)
        Nothing -> Nothing

maybeFloatToMaybeString: Maybe Float -> Maybe String
maybeFloatToMaybeString maybeFloat =
    case maybeFloat of
        Just float -> Just(String.fromFloat float)
        Nothing -> Nothing



-- SELECT OPERATION TO DISPLAY IN MODAL
viewOperationModal : List Operation -> Model -> Html Msg
viewOperationModal operations operationModel =
    case operationModel.content of
        IdOnly operationId -> 
            let
                operationToDisplay = getOperationById operationId operations
            in 
                case operationToDisplay of
                    Just operation -> displayOperationModal operation DisplayOperationModal
                    Nothing -> emptyDiv
        
        Validated operation -> 
            displayOperationModal operation ModifyOperationModal
        
        _ -> emptyDiv

emptyDiv : Html Msg
emptyDiv = div [] []

getOperationById: Int -> List Operation -> Maybe Operation
getOperationById operationId operations =
    List.filter (\ op -> (op.id == operationId)) operations
        |> getSingleOperation

getSingleOperation: List Operation -> Maybe Operation
getSingleOperation operations =
    if (List.length operations) == 1 then List.head operations else Nothing


-- VIEW OPERATION IN A EDITABLE OR READ-ONLY MODAL
displayOperationModal : Operation -> Modal -> Html Msg
displayOperationModal operation modal =
    div [class "modal is-operation-modal"]
        [div [class "modal-background"][]
        ,div [class "modal-card"]
            [header [class "modal-card-head"]
                    (viewOperationHeader operation modal)
            ,section [class "modal-card-body"]
                     [table [class "table is-budget-tab-content is-striped is-hoverable is-fullwidth"]
                            [ viewOperationBody operation modal]
                     ]
            ,footer [class "modal-card-foot"]
                    (viewOperationFooter modal)
            ]
        ]

viewOperationHeader: Operation -> Modal -> List (Html Msg)
viewOperationHeader operation modal =
    case modal of
        DisplayOperationModal -> [p [class "modal-card-title"] [ text operation.name ]
                                    ,button [class "button is-rounded is-success", onClick <| ModifyOperationClicked operation] 
                                            [span [class "icon is-small"] 
                                                  [i [class "fas fa-pencil-alt"] []]
                                            ]
                                    ,button [class "button is-rounded", onClick CloseOperationModalClicked]
                                            [span [class "icon is-small"] 
                                                  [i [class "fas fa-times"] []]
                                            ]
                                    ]
        _ -> [p [class "modal-card-title"] [ text operation.name ]] 

viewOperationBody: Operation -> Modal -> Html Msg
viewOperationBody operation modal =
    case modal of
        DisplayOperationModal -> viewOperationFields operation viewOperationReadOnly
        ModifyOperationModal -> viewOperationFields operation viewOperationInput
        _ -> emptyDiv 


-- according to the type of the modal use readOnly or Input fields to view operation details
viewOperationFields: Operation -> (String -> (String -> Msg) -> String -> Html Msg) -> Html Msg
viewOperationFields operation callback =
        tbody [] [callback "nom" SetName operation.name
                , callback "n° devis" SetQuotationReference <| Maybe.withDefault "" operation.quotation.quotationReference
                , callback "date du devis" SetQuotationDate <| Maybe.withDefault "" operation.quotation.quotationDate
                , callback "montant du devis" SetQuotationAmount operation.quotation.quotationAmount.stringValue
                , callback "n° facture" SetInvoiceReference <| Maybe.withDefault "" operation.invoice.invoiceReference
                , callback "date facture" SetInvoiceDate <| Maybe.withDefault "" operation.invoice.invoiceDate
                , callback "montant facture" SetInvoiceAmount operation.invoice.invoiceAmount.stringValue
                , callback "fournisseur" SetStore operation.store
                , callback "commentaire" SetComment <| Maybe.withDefault "" operation.comment
            ]

viewOperationReadOnly: String -> (String -> Msg) -> String -> Html Msg
viewOperationReadOnly label msg val =
    tr [] [th [] [text label]
          , td [] [text val]
          ]

viewOperationInput: String -> (String -> Msg) -> String -> Html Msg
viewOperationInput label msg val =
    tr [] [th [] [text label]
          , td [] [input [ type_ "text", value val, onInput msg] []]
          ]

viewOperationFooter: Modal -> List (Html Msg)
viewOperationFooter modal =
    case modal of
        ModifyOperationModal 
            -> [button [class "button is-success"] [ text "Enregistrer"]
               , button [class "button is-warning", onClick CloseOperationModalClicked] [ text "Supprimer"]
               , button [class "button", onClick CloseOperationModalClicked] [ text "Annuler"]
               ]
        _ -> [emptyDiv] 




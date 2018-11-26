module OperationMuv exposing (Operation, Msg, Model, Notification(..), update, initModel, operationEncoder, operationDecoder, viewOperations)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onBlur)
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required, optional, custom)
import Json.Encode


{--
This file contains an operation related MUV structure (Model Update View)
The view handles the display of operation list in a table
and of single operation in a modal

Module exposes:
* Operation type, encoder and decoder
* Operation MUV structure: subModel, subMsg, update, notifications and view
--}



{-------------------------
        MODEL
--------------------------}
type alias Model =
    { current: Operation 
    , modal: Modal }

initModel =
    Model NoOperation NoModal



{-------------------------
        TYPES
--------------------------}
type Notification 
    = NoNotification
    | SendPutRequest Operation

type Operation
    = NoOperation
    | IdOnly Int
    | Validated Int Core


{-- private types --}
type alias Core =
    { name: String
    , store: String
    , comment: Maybe String
    , quotation: AccountingEntry
    , invoice: AccountingEntry
    }

type alias AccountingEntry =
    { reference: Maybe String
    , date: Maybe String
    , amount : AmountField
    }

-- allows to use number in input field
type alias AmountField = 
    { value: Maybe Float
    , stringValue: String
    }

type Modal 
    = NoModal
    | DisplayOperation
    | ModifyOperation
    | CreateOperation




{-------------------------
        UPDATE
--------------------------}

type Msg
    = SelectOperationClicked Int
    | CloseOperationModalClicked
    | ModifyOperationClicked Int Core
    | SaveModifiedOperationClicked
    | SetName String
    | SetQuotationReference String
    | SetQuotationDate String
    | SetQuotationAmount String
    | SetInvoiceReference String
    | SetInvoiceDate String
    | SetInvoiceAmount String
    | SetStore String
    | SetComment String

update : Msg -> Model -> ( Model, Notification, Cmd Msg )
update msg model =
    case msg of
        SelectOperationClicked operationId ->
            ( { model | modal = DisplayOperation, current = IdOnly operationId }
            , NoNotification
            , Cmd.none )
        
        CloseOperationModalClicked ->
            ( { model | modal = NoModal, current = NoOperation }
            , NoNotification
            , Cmd.none)
        
        ModifyOperationClicked id operation ->
            ( { model | modal = ModifyOperation, current = Validated id operation }
            , NoNotification
            , Cmd.none )
        
        SaveModifiedOperationClicked ->
            case model.current of
                Validated id operation -> 
                    ( { model | modal = NoModal, current = Validated id operation }
                    , SendPutRequest (Validated id operation)
                    , Cmd.none )

                _ -> ( { model | modal = NoModal, current = NoOperation }
                    , NoNotification
                    , Cmd.none )

        SetName value ->
            case model.current of
                Validated id operation -> let 
                                            newContent = { operation | name = value} 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetQuotationReference value ->
            case model.current of
                Validated id operation -> let 
                                            oldQuotation = operation.quotation
                                            newQuotation = { oldQuotation | reference = convertStringToMaybeString value }
                                            newContent = { operation | quotation = newQuotation } 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetQuotationDate value ->
            case model.current of
                Validated id operation -> let 
                                            oldQuotation = operation.quotation
                                            newQuotation = { oldQuotation | date = convertStringToMaybeString value }
                                            newContent = { operation | quotation = newQuotation } 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetQuotationAmount value ->
            case model.current of
                Validated id operation -> 
                    case (String.toFloat value) of
                        Just amount -> let 
                                            oldQuotation = operation.quotation
                                            newQuotation = { oldQuotation | amount  = AmountField (Just amount) value }
                                            newContent = { operation | quotation = newQuotation } 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                        Nothing -> let 
                                        oldQuotation = operation.quotation
                                        newQuotation = { oldQuotation | amount  = AmountField Nothing value }
                                        newContent = { operation | quotation = newQuotation } 
                                    in
                                        ( { model | current = Validated id newContent }
                                        , NoNotification
                                        , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetInvoiceReference value ->
            case model.current of
                Validated id operation -> let 
                                            oldInvoice = operation.invoice
                                            newInvoice = { oldInvoice | reference = convertStringToMaybeString value }
                                            newContent = { operation | invoice = newInvoice } 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetInvoiceDate value ->
            case model.current of
                Validated id operation -> let 
                                            oldInvoice = operation.invoice
                                            newInvoice = { oldInvoice | date = convertStringToMaybeString value }
                                            newContent = { operation | invoice = newInvoice } 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetInvoiceAmount value ->
            case model.current of
                Validated id operation -> 
                    case (String.toFloat value) of
                        Just amount -> let 
                                            oldInvoice = operation.invoice
                                            newInvoice = { oldInvoice | amount = AmountField (Just amount) value }
                                            newContent = { operation | invoice = newInvoice } 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                        Nothing -> let 
                                        oldInvoice = operation.invoice
                                        newInvoice = { oldInvoice | amount = AmountField Nothing value }
                                        newContent = { operation | invoice = newInvoice } 
                                    in
                                        ( { model | current = Validated id newContent }
                                        , NoNotification
                                        , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetStore value ->
            case model.current of
                Validated id operation -> let 
                                            newContent = { operation | store = value} 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetComment value ->
            case model.current of
                Validated id operation -> let 
                                            newContent = { operation | comment = convertStringToMaybeString value } 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

convertStringToMaybeString: String -> Maybe String
convertStringToMaybeString stringToConvert =
    case stringToConvert of
        "" -> Nothing
        _ -> Just stringToConvert


{-------------------------
        DECODER
--------------------------}
operationDecoder: Decoder Operation
operationDecoder =
    Json.Decode.succeed toDecoder
       |> Json.Decode.Pipeline.required "id" Json.Decode.int
       |> Json.Decode.Pipeline.required "name" Json.Decode.string
       |> Json.Decode.Pipeline.required "store" Json.Decode.string
       |> Json.Decode.Pipeline.optional "comment" (Json.Decode.nullable Json.Decode.string) Nothing
       |> Json.Decode.Pipeline.optional "quotation" (Json.Decode.nullable Json.Decode.string) Nothing
       |> Json.Decode.Pipeline.optional "quotationDate" (Json.Decode.nullable dateDecoder) Nothing 
       |> Json.Decode.Pipeline.custom (Json.Decode.field "quotationAmount" amountDecoder)
       |> Json.Decode.Pipeline.optional "invoice" (Json.Decode.nullable Json.Decode.string) Nothing 
       |> Json.Decode.Pipeline.optional "invoiceDate" (Json.Decode.nullable dateDecoder) Nothing 
       |> Json.Decode.Pipeline.custom (Json.Decode.field "invoiceAmount" amountDecoder)
       |> Json.Decode.Pipeline.resolve

toDecoder: Int -> String -> String -> Maybe String -> Maybe String -> Maybe String -> AmountField -> Maybe String -> Maybe String -> AmountField -> Decoder Operation
toDecoder id name store comment quotationReference  quotationDate quotationAmount  reference date amount =
    let
        quotation = AccountingEntry quotationReference  quotationDate quotationAmount 
        invoice = AccountingEntry reference date amount
    in
        Json.Decode.succeed <| Validated id <| Core name store comment quotation invoice
    

dateDecoder: Decoder String
dateDecoder =
    Json.Decode.succeed toDateString
        |> Json.Decode.Pipeline.required "dayOfMonth" Json.Decode.int
        |> Json.Decode.Pipeline.required "monthOfYear" Json.Decode.int
        |> Json.Decode.Pipeline.required "yearOfEra" Json.Decode.int

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

centsToEuros: Maybe Int -> Maybe Float
centsToEuros maybeAmount =
    case maybeAmount of
        Just amount -> Just ((toFloat amount) / 100)
        Nothing -> Nothing


{-------------------------
        ENCODER
--------------------------}
operationEncoder: Operation -> Json.Encode.Value
operationEncoder operation =
    case operation of
        Validated id core ->
            Json.Encode.object 
                [ ("id", Json.Encode.int id)
                , ("name", Json.Encode.string core.name)
                , ("store", Json.Encode.string core.store)
                , ("comment", encodeMaybeString core.comment)
                , ("quotation", encodeMaybeString core.quotation.reference)
                , ("quotationDate", encodeMaybeString core.quotation.date)
                , ("quotationAmount", encodeAmount core.quotation.amount)
                , ("invoice", encodeMaybeString core.invoice.reference)
                , ("invoiceDate", encodeMaybeString core.invoice.date)
                , ("invoiceAmount", encodeAmount core.invoice.amount)
                ]
        _ -> Json.Encode.null

encodeMaybeString: Maybe String -> Json.Encode.Value
encodeMaybeString maybeString =
    case maybeString of
        Just value -> Json.Encode.string value
        Nothing -> Json.Encode.null

encodeAmount: AmountField -> Json.Encode.Value
encodeAmount amountField =
    encodeMaybeFloat amountField.value

encodeMaybeFloat: Maybe Float -> Json.Encode.Value
encodeMaybeFloat maybeFloat =
    case maybeFloat of
        Just value -> Json.Encode.int <| euroToCents value
        Nothing -> Json.Encode.null

euroToCents: Float -> Int
euroToCents floatAmount =
    round <| floatAmount * 100


{-------------------------
        VIEW
--------------------------}

-- VIEW ALL OPERATIONS IN A TABLE
viewOperations: List Operation -> Model -> Html Msg
viewOperations operations operationModel =
    div [] [ viewAddButton
           , table [ class "table is-budget-tab-content is-striped is-hoverable is-fullwidth"]
                  [ viewOperationsHeaderRow 
                  , viewOperationsRows operations ]
           , viewOperationModal operations operationModel ]

viewAddButton: Html Msg
viewAddButton =
--    button  [class "button is-rounded is-hovered is-pulled-right is-plus-button", onClick AddOperationClicked ] 
    button  [class "button is-rounded is-hovered is-pulled-right is-plus-button" ] 
            [span [class "icon is-small"] 
                    [i [class "fas fa-plus"] []]
            ]

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
        case operation of
            Validated id core -> 
                tr [ onClick <| SelectOperationClicked id ] [ th [] [text core.name]
                    , td [] [text <| Maybe.withDefault "" core.quotation.reference ]
                    , td [] [text <| Maybe.withDefault "" core.quotation.date ]
                    , td [] [text <| core.quotation.amount.stringValue ]
                    , td [] [text <| Maybe.withDefault "" core.invoice.reference ]
                    , td [] [text <| Maybe.withDefault "" core.invoice.date ]
                    , td [] [text core.invoice.amount.stringValue ]
                    , td [] [text core.store ]
                    , td [] [text <| Maybe.withDefault "" core.comment ]
                ]
            _ -> emptyDiv


maybeFloatToMaybeString: Maybe Float -> Maybe String
maybeFloatToMaybeString maybeFloat =
    case maybeFloat of
        Just float -> Just(String.fromFloat float)
        Nothing -> Nothing



-- SELECT OPERATION TO DISPLAY IN MODAL
viewOperationModal : List Operation -> Model -> Html Msg
viewOperationModal operations operationModel =
    case (operationModel.modal, operationModel.current) of
        (NoModal, _) -> emptyDiv

        (_ , IdOnly id) -> 
            let
                operationToDisplay = getOperationById id operations
            in 
                case operationToDisplay of
                    Just operation -> displayOperationModal id operation DisplayOperation
                    Nothing -> emptyDiv
        
        (_, Validated id operation) -> 
            displayOperationModal id operation ModifyOperation
        
        (_, _) -> emptyDiv

emptyDiv : Html Msg
emptyDiv = div [] []

getOperationById: Int -> List Operation -> Maybe Core
getOperationById operationId operations =
    List.filterMap (isSearchedOperation operationId) operations
        |> List.map (\ (_, core) -> core)
        |> List.head

isSearchedOperation: Int -> Operation -> Maybe (Int, Core)
isSearchedOperation operationId element = 
    case element of
        Validated id core -> if id == operationId then Just (id, core) else Nothing
        _ -> Nothing

-- VIEW OPERATION IN A EDITABLE OR READ-ONLY MODAL
displayOperationModal : Int -> Core -> Modal -> Html Msg
displayOperationModal id core modal =
    div [class "modal is-operation-modal"]
        [div [class "modal-background"][]
        ,div [class "modal-card"]
            [header [class "modal-card-head"]
                    (viewOperationHeader id core modal)
            ,section [class "modal-card-body"]
                     [table [class "table is-budget-tab-content is-striped is-hoverable is-fullwidth"]
                            [ viewOperationBody core modal]
                     ]
            ,footer [class "modal-card-foot"]
                    (viewOperationFooter modal)
            ]
        ]

viewOperationHeader: Int -> Core -> Modal -> List (Html Msg)
viewOperationHeader id core modal =
    case modal of
        DisplayOperation -> [p [class "modal-card-title"] [ text core.name ]
                                    ,button [class "button is-rounded is-success", onClick <| ModifyOperationClicked id core] 
                                            [span [class "icon is-small"] 
                                                  [i [class "fas fa-pencil-alt"] []]
                                            ]
                                    ,button [class "button is-rounded", onClick CloseOperationModalClicked]
                                            [span [class "icon is-small"] 
                                                  [i [class "fas fa-times"] []]
                                            ]
                                    ]
        _ -> [p [class "modal-card-title"] [ text core.name ]] 

viewOperationBody: Core -> Modal -> Html Msg
viewOperationBody operation modal =
    case modal of
        DisplayOperation -> viewOperationFields operation viewOperationReadOnly
        ModifyOperation -> viewOperationFields operation viewOperationInput
        _ -> emptyDiv 


-- according to the type of the modal use readOnly or Input fields to view operation details
viewOperationFields: Core -> (String -> (String -> Msg) -> String -> Html Msg) -> Html Msg
viewOperationFields operation callback =
        tbody [] [callback "nom" SetName operation.name
                , callback "n° devis" SetQuotationReference <| Maybe.withDefault "" operation.quotation.reference
                , callback "date du devis" SetQuotationDate <| Maybe.withDefault "" operation.quotation.date
                , callback "montant du devis" SetQuotationAmount operation.quotation.amount.stringValue
                , callback "n° facture" SetInvoiceReference <| Maybe.withDefault "" operation.invoice.reference
                , callback "date facture" SetInvoiceDate <| Maybe.withDefault "" operation.invoice.date
                , callback "montant facture" SetInvoiceAmount operation.invoice.amount.stringValue
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
        ModifyOperation 
            -> [button [class "button is-success", onClick SaveModifiedOperationClicked] [ text "Enregistrer"]
               , button [class "button is-warning", onClick CloseOperationModalClicked] [ text "Supprimer"]
               , button [class "button", onClick CloseOperationModalClicked] [ text "Annuler"]
               ]
        _ -> [emptyDiv] 




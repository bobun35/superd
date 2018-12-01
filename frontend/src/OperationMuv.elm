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

type Operation
    = NoOperation
    | IdOnly Int
    | Validated Int Content
    | Create Content


{-- private types --}
type alias Content =
    { name: String
    , store: String
    , comment: Maybe String
    , quotation: AccountingEntry
    , invoice: AccountingEntry
    }

emptyContent = Content "" "" Nothing emptyAccountingEntry emptyAccountingEntry

type alias AccountingEntry =
    { reference: Maybe String
    , date: Maybe String
    , amount : AmountField
    }

emptyAccountingEntry = AccountingEntry Nothing Nothing <| AmountField Nothing ""

-- allows to use number in input field
type alias AmountField = 
    { value: Maybe Float
    , stringValue: String
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
    | SendPutRequest Operation
    | SendPostRequest Operation

type Msg
    = SelectClicked Int
    | CloseModalClicked
    | ModifyClicked Int Content
    | SaveClicked
    | AddClicked
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
        SelectClicked operationId ->
            ( { model | modal = ReadOnlyModal, current = IdOnly operationId }
            , NoNotification
            , Cmd.none )
        
        CloseModalClicked ->
            ( { model | modal = NoModal, current = NoOperation }
            , NoNotification
            , Cmd.none)
        
        ModifyClicked id operation ->
            ( { model | modal = ModifyModal, current = Validated id operation }
            , NoNotification
            , Cmd.none )
        
        SaveClicked ->
            case model.current of
                Validated id operation -> 
                    ( { model | modal = NoModal, current =  NoOperation }
                    , SendPutRequest (Validated id operation)
                    , Cmd.none )
                
                Create content ->
                    ( { model | modal = NoModal, current = NoOperation }
                    , SendPostRequest (Create content)
                    , Cmd.none )

                _ -> ( { model | modal = NoModal, current = NoOperation }
                    , NoNotification
                    , Cmd.none )

        AddClicked ->
            ( { model | modal = CreateModal, current = Create emptyContent }
            , NoNotification
            , Cmd.none)

        SetName value ->
            case model.current of
                Validated id content ->    let 
                                            newContent = { content | name = value} 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                Create content ->  let 
                                    newContent = { content | name = value} 
                                in
                                ( { model | current = Create newContent }
                                , NoNotification
                                , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetQuotationReference value ->
            case model.current of
                Validated id content ->    let 
                                            newQuotation = updateAccountingEntry content.quotation "reference" value
                                            newContent = { content | quotation = newQuotation } 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                Create content ->  let
                                    newQuotation = updateAccountingEntry content.quotation "reference" value
                                    newContent = { content | quotation = newQuotation } 
                                in
                                    ( { model | current = Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetQuotationDate value -> 
            case model.current of
                Validated id content ->    let    
                                            newQuotation = updateAccountingEntry content.quotation "date" value
                                            newContent = { content | quotation = newQuotation } 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                Create content ->  let    
                                    newQuotation = updateAccountingEntry content.quotation "date" value
                                    newContent = { content | quotation = newQuotation } 
                                in
                                    ( { model | current = Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetQuotationAmount value ->
            case model.current of
                Validated id content -> 
                        let    
                            newQuotation = updateAccountingEntry content.quotation "amount" value
                            newContent = { content | quotation = newQuotation } 
                        in
                            ( { model | current = Validated id newContent }
                            , NoNotification
                            , Cmd.none)
                Create content -> 
                        let    
                            newQuotation = updateAccountingEntry content.quotation "amount" value
                            newContent = { content | quotation = newQuotation } 
                        in
                            ( { model | current = Create newContent }
                            , NoNotification
                            , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetInvoiceReference value ->
            case model.current of
                Validated id content ->    
                        let 
                            newInvoice = updateAccountingEntry content.invoice "reference" value
                            newContent = { content | invoice = newInvoice } 
                        in
                            ( { model | current = Validated id newContent }
                            , NoNotification
                            , Cmd.none)
                Create content ->  let
                                    newInvoice = updateAccountingEntry content.invoice "reference" value
                                    newContent = { content | invoice = newInvoice } 
                                in
                                    ( { model | current = Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetInvoiceDate value ->
            case model.current of
                Validated id content ->    
                        let 
                            newInvoice = updateAccountingEntry content.invoice "date" value
                            newContent = { content | invoice = newInvoice } 
                        in
                            ( { model | current = Validated id newContent }
                            , NoNotification
                            , Cmd.none)
                Create content ->  let
                                    newInvoice = updateAccountingEntry content.invoice "date" value
                                    newContent = { content | invoice = newInvoice } 
                                in
                                    ( { model | current = Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetInvoiceAmount value ->
            case model.current of
                Validated id content ->    
                        let 
                            newInvoice = updateAccountingEntry content.invoice "amount" value
                            newContent = { content | invoice = newInvoice } 
                        in
                            ( { model | current = Validated id newContent }
                            , NoNotification
                            , Cmd.none)
                Create content ->  let
                                    newInvoice = updateAccountingEntry content.invoice "amount" value
                                    newContent = { content | invoice = newInvoice } 
                                in
                                    ( { model | current = Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetStore value ->
            case model.current of
                Validated id content ->   let 
                                            newContent = { content | store = value} 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                Create content ->  let 
                                    newContent = { content | store = value} 
                                in
                                    ( { model | current = Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetComment value ->
            case model.current of
                Validated id content ->    let 
                                            newContent = { content | comment = convertStringToMaybeString value } 
                                        in
                                            ( { model | current = Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                Create content ->  let 
                                    newContent = { content | comment = convertStringToMaybeString value} 
                                in
                                    ( { model | current = Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

convertStringToMaybeString: String -> Maybe String
convertStringToMaybeString stringToConvert =
    case stringToConvert of
        "" -> Nothing
        _ -> Just stringToConvert

updateAccountingEntry: AccountingEntry -> String -> String -> AccountingEntry
updateAccountingEntry accountingEntry field value =
    case field of
        "reference" -> { accountingEntry | reference = convertStringToMaybeString value }
        "date" -> { accountingEntry | date = convertStringToMaybeString value }
        "amount" -> case (String.toFloat value) of
                        Just amount -> { accountingEntry | amount  = AmountField (Just amount) value }
                        Nothing -> { accountingEntry | amount  = AmountField Nothing value }
        _ -> accountingEntry


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
        Json.Decode.succeed <| Validated id <| Content name store comment quotation invoice
    

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
        Validated id content ->
            Json.Encode.object 
                [ ("id", Json.Encode.int id)
                , ("name", Json.Encode.string content.name)
                , ("store", Json.Encode.string content.store)
                , ("comment", encodeMaybeString content.comment)
                , ("quotation", encodeMaybeString content.quotation.reference)
                , ("quotationDate", encodeMaybeString content.quotation.date)
                , ("quotationAmount", encodeAmount content.quotation.amount)
                , ("invoice", encodeMaybeString content.invoice.reference)
                , ("invoiceDate", encodeMaybeString content.invoice.date)
                , ("invoiceAmount", encodeAmount content.invoice.amount)
                ]
        Create content ->
            Json.Encode.object 
                [ ("name", Json.Encode.string content.name)
                , ("store", Json.Encode.string content.store)
                , ("comment", encodeMaybeString content.comment)
                , ("quotation", encodeMaybeString content.quotation.reference)
                , ("quotationDate", encodeMaybeString content.quotation.date)
                , ("quotationAmount", encodeAmount content.quotation.amount)
                , ("invoice", encodeMaybeString content.invoice.reference)
                , ("invoiceDate", encodeMaybeString content.invoice.date)
                , ("invoiceAmount", encodeAmount content.invoice.amount)
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
    button  [class "button is-rounded is-hovered is-pulled-right is-plus-button", onClick AddClicked ] 
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
            Validated id content -> 
                tr [ onClick <| SelectClicked id ] [ th [] [text content.name]
                    , td [] [text <| Maybe.withDefault "" content.quotation.reference ]
                    , td [] [text <| Maybe.withDefault "" content.quotation.date ]
                    , td [] [text <| content.quotation.amount.stringValue ]
                    , td [] [text <| Maybe.withDefault "" content.invoice.reference ]
                    , td [] [text <| Maybe.withDefault "" content.invoice.date ]
                    , td [] [text content.invoice.amount.stringValue ]
                    , td [] [text content.store ]
                    , td [] [text <| Maybe.withDefault "" content.comment ]
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
                    Just operation -> displayOperationModal (Just id) operation ReadOnlyModal
                    Nothing -> emptyDiv
        
        (_, Validated id operation) -> 
            displayOperationModal (Just id) operation ModifyModal
        
        (CreateModal, Create content) ->
            displayOperationModal Nothing content CreateModal
        
        (_, _) -> emptyDiv

emptyDiv : Html Msg
emptyDiv = div [] []

getOperationById: Int -> List Operation -> Maybe Content
getOperationById operationId operations =
    List.filterMap (isSearchedOperation operationId) operations
        |> List.map (\ (_, content) -> content)
        |> List.head

isSearchedOperation: Int -> Operation -> Maybe (Int, Content)
isSearchedOperation operationId element = 
    case element of
        Validated id content -> if id == operationId then Just (id, content) else Nothing
        _ -> Nothing

-- VIEW OPERATION IN A EDITABLE OR READ-ONLY MODAL
displayOperationModal : Maybe Int -> Content -> Modal -> Html Msg
displayOperationModal maybeId content modal =
    div [class "modal is-operation-modal"]
        [div [class "modal-background"][]
        ,div [class "modal-card"]
            [header [class "modal-card-head"]
                    (viewOperationHeader maybeId content modal)
            ,section [class "modal-card-body"]
                     [table [class "table is-budget-tab-content is-striped is-hoverable is-fullwidth"]
                            [ viewOperationBody content modal]
                     ]
            ,footer [class "modal-card-foot"]
                    (viewOperationFooter modal)
            ]
        ]

viewOperationHeader: Maybe Int -> Content -> Modal -> List (Html Msg)
viewOperationHeader maybeId content modal =
    case (modal, maybeId) of
        (ReadOnlyModal, Just id) -> [p [class "modal-card-title"] [ text content.name ]
                                    ,button [class "button is-rounded is-success", onClick <| ModifyClicked id content] 
                                            [span [class "icon is-small"] 
                                                  [i [class "fas fa-pencil-alt"] []]
                                            ]
                                    ,button [class "button is-rounded", onClick CloseModalClicked]
                                            [span [class "icon is-small"] 
                                                  [i [class "fas fa-times"] []]
                                            ]
                                    ]
        (_, _) -> [p [class "modal-card-title"] [ text content.name ]] 

viewOperationBody: Content -> Modal -> Html Msg
viewOperationBody content modal =
    case modal of
        ReadOnlyModal -> viewOperationFields content viewOperationReadOnly
        ModifyModal -> viewOperationFields content viewOperationInput
        CreateModal -> viewOperationFields content viewOperationInput
        _ -> emptyDiv 


-- according to the type of the modal use readOnly or Input fields to view operation details
viewOperationFields: Content -> (String -> (String -> Msg) -> String -> Html Msg) -> Html Msg
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
        ModifyModal -> modalSaveAndCloseButtons
        CreateModal -> modalSaveAndCloseButtons
        _ -> [emptyDiv] 

modalSaveAndCloseButtons: List (Html Msg)
modalSaveAndCloseButtons =
    [button [class "button is-success", onClick SaveClicked] [ text "Enregistrer"]
               , button [class "button is-warning", onClick CloseModalClicked] [ text "Supprimer"]
               , button [class "button", onClick CloseModalClicked] [ text "Annuler"]
               ]


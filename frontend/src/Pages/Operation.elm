module Pages.Operation exposing ( Msg
                                , Model
                                , Notification(..)
                                , update
                                , initModel
                                , viewOperations
                                )

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Json.Decode exposing (Decoder)
import Json.Encode
import Data.Operation


{-------------------------
        MODEL
--------------------------}
type alias Model =
    { current: Data.Operation.Operation
    , modal: Modal }

initModel =
    Model Data.Operation.NoOperation NoModal


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
    | SendPutRequest Data.Operation.Operation
    | SendPostRequest Data.Operation.Operation
    | SendDeleteRequest Data.Operation.Operation

type Msg
    = SelectClicked Int
    | CloseModalClicked
    | ModifyClicked Int Data.Operation.Content
    | SaveClicked
    | AddClicked
    | DeleteClicked
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
            ( { model | modal = ReadOnlyModal, current = Data.Operation.IdOnly operationId }
            , NoNotification
            , Cmd.none )

        CloseModalClicked ->
            ( { model | modal = NoModal, current = Data.Operation.NoOperation }
            , NoNotification
            , Cmd.none)

        ModifyClicked id operation ->
            ( { model | modal = ModifyModal, current = Data.Operation.Validated id operation }
            , NoNotification
            , Cmd.none )

        SaveClicked ->
            case model.current of
                Data.Operation.Validated id operation ->
                    ( { model | modal = NoModal, current =  Data.Operation.NoOperation }
                    , SendPutRequest (Data.Operation.Validated id operation)
                    , Cmd.none )

                Data.Operation.Create content ->
                    ( { model | modal = NoModal, current = Data.Operation.NoOperation }
                    , SendPostRequest (Data.Operation.Create content)
                    , Cmd.none )

                _ -> ( { model | modal = NoModal, current = Data.Operation.NoOperation }
                    , NoNotification
                    , Cmd.none )

        AddClicked ->
            ( { model | modal = CreateModal, current = Data.Operation.Create Data.Operation.emptyContent }
            , NoNotification
            , Cmd.none)

        DeleteClicked ->
            case model.current of
                Data.Operation.Validated id operation ->
                    ( { model | modal = NoModal, current =  Data.Operation.NoOperation }
                    , SendDeleteRequest (Data.Operation.Validated id operation)
                    , Cmd.none )

                _ -> ( { model | modal = NoModal, current = Data.Operation.NoOperation }
                    , NoNotification
                    , Cmd.none )

        SetName value ->
            case model.current of
                Data.Operation.Validated id content ->
                                        let
                                            newContent = { content | name = value }
                                        in
                                            ( { model | current = Data.Operation.Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                Data.Operation.Create content ->
                                let
                                    newContent = { content | name = value}
                                in
                                ( { model | current = Data.Operation.Create newContent }
                                , NoNotification
                                , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetQuotationReference value ->
            case model.current of
                Data.Operation.Validated id content ->
                                        let
                                            newQuotation = updateAccountingEntry content.quotation "reference" value
                                            newContent = { content | quotation = newQuotation }
                                        in
                                            ( { model | current = Data.Operation.Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                Data.Operation.Create content ->
                                let
                                    newQuotation = updateAccountingEntry content.quotation "reference" value
                                    newContent = { content | quotation = newQuotation }
                                in
                                    ( { model | current = Data.Operation.Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetQuotationDate value ->
            case model.current of
                Data.Operation.Validated id content ->
                                        let
                                            newQuotation = updateAccountingEntry content.quotation "date" value
                                            newContent = { content | quotation = newQuotation }
                                        in
                                            ( { model | current = Data.Operation.Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                Data.Operation.Create content ->
                                let
                                    newQuotation = updateAccountingEntry content.quotation "date" value
                                    newContent = { content | quotation = newQuotation }
                                in
                                    ( { model | current = Data.Operation.Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetQuotationAmount value ->
            case model.current of
                Data.Operation.Validated id content ->
                        let
                            newQuotation = updateAccountingEntry content.quotation "amount" value
                            newContent = { content | quotation = newQuotation }
                        in
                            ( { model | current = Data.Operation.Validated id newContent }
                            , NoNotification
                            , Cmd.none)
                Data.Operation.Create content ->
                        let
                            newQuotation = updateAccountingEntry content.quotation "amount" value
                            newContent = { content | quotation = newQuotation }
                        in
                            ( { model | current = Data.Operation.Create newContent }
                            , NoNotification
                            , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetInvoiceReference value ->
            case model.current of
                Data.Operation.Validated id content ->
                        let
                            newInvoice = updateAccountingEntry content.invoice "reference" value
                            newContent = { content | invoice = newInvoice }
                        in
                            ( { model | current = Data.Operation.Validated id newContent }
                            , NoNotification
                            , Cmd.none)
                Data.Operation.Create content ->
                                let
                                    newInvoice = updateAccountingEntry content.invoice "reference" value
                                    newContent = { content | invoice = newInvoice }
                                in
                                    ( { model | current = Data.Operation.Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetInvoiceDate value ->
            case model.current of
                Data.Operation.Validated id content ->
                        let
                            newInvoice = updateAccountingEntry content.invoice "date" value
                            newContent = { content | invoice = newInvoice }
                        in
                            ( { model | current = Data.Operation.Validated id newContent }
                            , NoNotification
                            , Cmd.none)
                Data.Operation.Create content ->
                                let
                                    newInvoice = updateAccountingEntry content.invoice "date" value
                                    newContent = { content | invoice = newInvoice }
                                in
                                    ( { model | current = Data.Operation.Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetInvoiceAmount value ->
            case model.current of
                Data.Operation.Validated id content ->
                        let
                            newInvoice = updateAccountingEntry content.invoice "amount" value
                            newContent = { content | invoice = newInvoice }
                        in
                            ( { model | current = Data.Operation.Validated id newContent }
                            , NoNotification
                            , Cmd.none)
                Data.Operation.Create content ->
                                let
                                    newInvoice = updateAccountingEntry content.invoice "amount" value
                                    newContent = { content | invoice = newInvoice }
                                in
                                    ( { model | current = Data.Operation.Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetStore value ->
            case model.current of
                Data.Operation.Validated id content ->
                                        let
                                            newContent = { content | store = value}
                                        in
                                            ( { model | current = Data.Operation.Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                Data.Operation.Create content ->
                                let
                                    newContent = { content | store = value}
                                in
                                    ( { model | current = Data.Operation.Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

        SetComment value ->
            case model.current of
                Data.Operation.Validated id content ->
                                        let
                                            newContent = { content | comment = convertStringToMaybeString value }
                                        in
                                            ( { model | current = Data.Operation.Validated id newContent }
                                            , NoNotification
                                            , Cmd.none)
                Data.Operation.Create content ->
                                let
                                    newContent = { content | comment = convertStringToMaybeString value}
                                in
                                    ( { model | current = Data.Operation.Create newContent }
                                    , NoNotification
                                    , Cmd.none)
                _ -> (model, NoNotification, Cmd.none)

convertStringToMaybeString: String -> Maybe String
convertStringToMaybeString stringToConvert =
    case stringToConvert of
        "" -> Nothing
        _ -> Just stringToConvert

updateAccountingEntry: Data.Operation.AccountingEntry -> String -> String -> Data.Operation.AccountingEntry
updateAccountingEntry accountingEntry field value =
    case field of
        "reference" -> { accountingEntry | reference = convertStringToMaybeString value }
        "date" -> { accountingEntry | date = convertStringToMaybeString value }
        "amount" -> case (String.toFloat value) of
                        Just amount -> { accountingEntry | amount  = Data.Operation.AmountField (Just amount) value }
                        Nothing -> { accountingEntry | amount  = Data.Operation.AmountField Nothing value }
        _ -> accountingEntry


{-------------------------
        VIEW
--------------------------}

-- VIEW ALL OPERATIONS IN A TABLE
viewOperations: Model -> List Data.Operation.Operation -> Html Msg
viewOperations operationModel operations =
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

viewOperationsRows: List Data.Operation.Operation -> Html Msg
viewOperationsRows operations =
    tbody [] (List.map viewOperationsRow operations)

viewOperationsRow: Data.Operation.Operation -> Html Msg
viewOperationsRow operation =
        case operation of
            Data.Operation.Validated id content ->
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
viewOperationModal : List Data.Operation.Operation -> Model -> Html Msg
viewOperationModal operations operationModel =
    case (operationModel.modal, operationModel.current) of
        (NoModal, _) -> emptyDiv

        (_ , Data.Operation.IdOnly id) ->
            let
                operationToDisplay = Data.Operation.getOperationById id operations
            in
                case operationToDisplay of
                    Just operation -> displayOperationModal (Just id) operation ReadOnlyModal
                    Nothing -> emptyDiv

        (_, Data.Operation.Validated id operation) ->
            displayOperationModal (Just id) operation ModifyModal

        (CreateModal, Data.Operation.Create content) ->
            displayOperationModal Nothing content CreateModal

        (_, _) -> emptyDiv

emptyDiv : Html Msg
emptyDiv = div [] []



-- VIEW OPERATION IN A EDITABLE OR READ-ONLY MODAL
displayOperationModal : Maybe Int -> Data.Operation.Content -> Modal -> Html Msg
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

viewOperationHeader: Maybe Int -> Data.Operation.Content -> Modal -> List (Html Msg)
viewOperationHeader maybeId content modal =
    case (modal, maybeId) of
        (ReadOnlyModal, Just id) -> [p [class "modal-card-title"] [ text content.name ]
                                    ,button [class "button is-rounded is-success"
                                            , onClick <| ModifyClicked id content]
                                            [span [class "icon is-small"]
                                                  [i [class "fas fa-pencil-alt"] []]
                                            ]
                                    ,button [class "button is-rounded", onClick CloseModalClicked]
                                            [span [class "icon is-small"]
                                                  [i [class "fas fa-times"] []]
                                            ]
                                    ]
        (_, _) -> [p [class "modal-card-title"] [ text content.name ]]

viewOperationBody: Data.Operation.Content -> Modal -> Html Msg
viewOperationBody content modal =
    case modal of
        ReadOnlyModal -> viewOperationFields content viewOperationReadOnly
        ModifyModal -> viewOperationFields content viewOperationInput
        CreateModal -> viewOperationFields content viewOperationInput
        _ -> emptyDiv


-- according to the type of the modal use readOnly or Input fields to view operation details
viewOperationFields: Data.Operation.Content -> ((String -> Msg) -> String -> Html Msg) -> Html Msg
viewOperationFields operation callback =
        tbody [] [ tr [] [ viewLabel "nom"
                         , callback SetName operation.name
                         , viewLabel ""
                         , viewEmptyCell
                         ]
                 , tr [] [ viewLabel "ref. devis"
                         , callback SetQuotationReference <| Maybe.withDefault "" operation.quotation.reference
                         , viewLabel "ref. facture"
                         , callback SetInvoiceReference <| Maybe.withDefault "" operation.invoice.reference
                         ]
                 , tr [] [ viewLabel "date devis"
                         , callback SetQuotationDate <| Maybe.withDefault "" operation.quotation.date
                         , viewLabel "date facture"
                         , callback SetInvoiceDate <| Maybe.withDefault "" operation.invoice.date
                         ]
                 , tr [] [ viewLabel "montant devis"
                         , callback SetQuotationAmount operation.quotation.amount.stringValue
                         , viewLabel "montant facture"
                         , callback SetInvoiceAmount operation.invoice.amount.stringValue
                         ]
                 , tr [] [ viewLabel "fournisseur"
                         , callback SetStore operation.store
                         , viewLabel ""
                         , viewEmptyCell
                         ]
                 , tr [] [ viewLabel "commentaire"
                         , callback SetComment <| Maybe.withDefault "" operation.comment
                         , viewLabel ""
                         , viewEmptyCell
                         ]
               ]


viewLabel: String -> Html Msg
viewLabel label =
    th [] [text label]

viewEmptyCell: Html Msg
viewEmptyCell =
    td [] []

viewOperationReadOnly: (String -> Msg) -> String -> Html Msg
viewOperationReadOnly msg val =
    td [] [text val]

viewOperationInput: (String -> Msg) -> String -> Html Msg
viewOperationInput msg val =
    td [] [input [ type_ "text", value val, onInput msg] []]

viewOperationFooter: Modal -> List (Html Msg)
viewOperationFooter modal =
    case modal of
        ModifyModal -> modalSaveCancelDeleteButtons
        CreateModal -> modalSaveAndCancelButtons
        _ -> [emptyDiv]

modalSaveAndCancelButtons: List (Html Msg)
modalSaveAndCancelButtons =
    [ successButton "Enregistrer" SaveClicked
    , cancelButton "Annuler" CloseModalClicked
    ]

modalSaveCancelDeleteButtons: List (Html Msg)
modalSaveCancelDeleteButtons =
    [ successButton "Enregistrer" SaveClicked
    , cancelButton "Annuler" CloseModalClicked
    , deleteButton "Supprimer" DeleteClicked
    ]

successButton: String -> Msg -> Html Msg
successButton label actionOnClick =
    div [class "button is-success", onClick actionOnClick]
        [span [class "icon is-small"]
              [i [class "fas fa-check"] []
              ]
        , span [] [text label]
        ]

cancelButton: String -> Msg -> Html Msg
cancelButton label actionOnClick =
    div [class "button is-info  is-outlined", onClick actionOnClick]
        [ span [] [text label]
        ]

deleteButton: String -> Msg -> Html Msg
deleteButton label actionOnClick =
    div [class "button is-danger is-outlined", onClick actionOnClick]
        [span [class "icon is-small"]
              [i [class "fas fa-times"] []
              ]
        , span [] [text label]
        ]

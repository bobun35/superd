module Pages.Operation exposing
    ( Model
    , Msg
    , Notification(..)
    , update
    , viewOperations
    )

import Data.Form as Form
import Data.Modal as Modal
import Data.Operation as Operation
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Utils.Validators exposing (..)
import Validate



{-------------------------
        MODEL
--------------------------}


type alias Model a =
    { a
        | currentOperation : Operation.Operation
        , modal : Modal.Modal
        , formErrors : List Form.Error
    }



{-------------------------
        UPDATE
--------------------------}


type Notification
    = NoNotification
    | SendPutRequest Operation.Operation
    | SendPostRequest Operation.Operation
    | SendDeleteRequest Operation.Operation


type Msg
    = SelectClicked Int
    | CloseModalClicked
    | ModifyClicked Int Operation.Content
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


update : Msg -> Model a -> ( Model a, Notification, Cmd Msg )
update msg model =
    case msg of
        SelectClicked operationId ->
            ( { model | modal = Modal.ReadOnlyModal, currentOperation = Operation.IdOnly operationId }
            , NoNotification
            , Cmd.none
            )

        CloseModalClicked ->
            ( { model | modal = Modal.NoModal, currentOperation = Operation.NoOperation }
            , NoNotification
            , Cmd.none
            )

        ModifyClicked id operation ->
            ( { model | modal = Modal.ModifyModal, currentOperation = Operation.Validated id operation }
            , NoNotification
            , Cmd.none
            )

        SaveClicked ->
            case model.currentOperation of
                Operation.Validated id content ->
                    case Validate.validate operationFormValidator content of
                        Ok _ ->
                            ( { model | modal = Modal.NoModal, currentOperation = Operation.NoOperation, formErrors = [] }
                            , SendPutRequest (Operation.Validated id content)
                            , Cmd.none
                            )

                        Err errors ->
                            ( { model | formErrors = errors }
                            , NoNotification
                            , Cmd.none
                            )

                Operation.Create content ->
                    case Validate.validate operationFormValidator content of
                        Ok _ ->
                            ( { model | modal = Modal.NoModal, currentOperation = Operation.NoOperation, formErrors = [] }
                            , SendPostRequest (Operation.Create content)
                            , Cmd.none
                            )

                        Err errors ->
                            ( { model | formErrors = errors }
                            , NoNotification
                            , Cmd.none
                            )

                _ ->
                    ( model
                    , NoNotification
                    , Cmd.none
                    )

        AddClicked ->
            ( { model | modal = Modal.CreateModal, currentOperation = Operation.Create Operation.emptyContent }
            , NoNotification
            , Cmd.none
            )

        DeleteClicked ->
            case model.currentOperation of
                Operation.Validated id operation ->
                    ( { model | modal = Modal.NoModal, currentOperation = Operation.NoOperation }
                    , SendDeleteRequest (Operation.Validated id operation)
                    , Cmd.none
                    )

                _ ->
                    ( { model | modal = Modal.NoModal, currentOperation = Operation.NoOperation }
                    , NoNotification
                    , Cmd.none
                    )

        SetName value ->
            case model.currentOperation of
                Operation.Validated id content ->
                    let
                        newContent =
                            { content | name = value }
                    in
                    ( { model | currentOperation = Operation.Validated id newContent }
                    , NoNotification
                    , Cmd.none
                    )

                Operation.Create content ->
                    let
                        newContent =
                            { content | name = value }
                    in
                    ( { model | currentOperation = Operation.Create newContent }
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        SetQuotationReference value ->
            case model.currentOperation of
                Operation.Validated id content ->
                    let
                        newQuotation =
                            updateAccountingEntry content.quotation "reference" value

                        newContent =
                            { content | quotation = newQuotation }
                    in
                    ( { model | currentOperation = Operation.Validated id newContent }
                    , NoNotification
                    , Cmd.none
                    )

                Operation.Create content ->
                    let
                        newQuotation =
                            updateAccountingEntry content.quotation "reference" value

                        newContent =
                            { content | quotation = newQuotation }
                    in
                    ( { model | currentOperation = Operation.Create newContent }
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        SetQuotationDate value ->
            case model.currentOperation of
                Operation.Validated id content ->
                    let
                        newQuotation =
                            updateAccountingEntry content.quotation "date" value

                        newContent =
                            { content | quotation = newQuotation }
                    in
                    ( { model | currentOperation = Operation.Validated id newContent }
                    , NoNotification
                    , Cmd.none
                    )

                Operation.Create content ->
                    let
                        newQuotation =
                            updateAccountingEntry content.quotation "date" value

                        newContent =
                            { content | quotation = newQuotation }
                    in
                    ( { model | currentOperation = Operation.Create newContent }
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        SetQuotationAmount value ->
            case model.currentOperation of
                Operation.Validated id content ->
                    let
                        newQuotation =
                            updateAccountingEntry content.quotation "amount" value

                        newContent =
                            { content | quotation = newQuotation }
                    in
                    ( { model | currentOperation = Operation.Validated id newContent }
                    , NoNotification
                    , Cmd.none
                    )

                Operation.Create content ->
                    let
                        newQuotation =
                            updateAccountingEntry content.quotation "amount" value

                        newContent =
                            { content | quotation = newQuotation }
                    in
                    ( { model | currentOperation = Operation.Create newContent }
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        SetInvoiceReference value ->
            case model.currentOperation of
                Operation.Validated id content ->
                    let
                        newInvoice =
                            updateAccountingEntry content.invoice "reference" value

                        newContent =
                            { content | invoice = newInvoice }
                    in
                    ( { model | currentOperation = Operation.Validated id newContent }
                    , NoNotification
                    , Cmd.none
                    )

                Operation.Create content ->
                    let
                        newInvoice =
                            updateAccountingEntry content.invoice "reference" value

                        newContent =
                            { content | invoice = newInvoice }
                    in
                    ( { model | currentOperation = Operation.Create newContent }
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        SetInvoiceDate value ->
            case model.currentOperation of
                Operation.Validated id content ->
                    let
                        newInvoice =
                            updateAccountingEntry content.invoice "date" value

                        newContent =
                            { content | invoice = newInvoice }
                    in
                    ( { model | currentOperation = Operation.Validated id newContent }
                    , NoNotification
                    , Cmd.none
                    )

                Operation.Create content ->
                    let
                        newInvoice =
                            updateAccountingEntry content.invoice "date" value

                        newContent =
                            { content | invoice = newInvoice }
                    in
                    ( { model | currentOperation = Operation.Create newContent }
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        SetInvoiceAmount value ->
            case model.currentOperation of
                Operation.Validated id content ->
                    let
                        newInvoice =
                            updateAccountingEntry content.invoice "amount" value

                        newContent =
                            { content | invoice = newInvoice }
                    in
                    ( { model | currentOperation = Operation.Validated id newContent }
                    , NoNotification
                    , Cmd.none
                    )

                Operation.Create content ->
                    let
                        newInvoice =
                            updateAccountingEntry content.invoice "amount" value

                        newContent =
                            { content | invoice = newInvoice }
                    in
                    ( { model | currentOperation = Operation.Create newContent }
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        SetStore value ->
            case model.currentOperation of
                Operation.Validated id content ->
                    let
                        newContent =
                            { content | store = value }
                    in
                    ( { model | currentOperation = Operation.Validated id newContent }
                    , NoNotification
                    , Cmd.none
                    )

                Operation.Create content ->
                    let
                        newContent =
                            { content | store = value }
                    in
                    ( { model | currentOperation = Operation.Create newContent }
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )

        SetComment value ->
            case model.currentOperation of
                Operation.Validated id content ->
                    let
                        newContent =
                            { content | comment = value }
                    in
                    ( { model | currentOperation = Operation.Validated id newContent }
                    , NoNotification
                    , Cmd.none
                    )

                Operation.Create content ->
                    let
                        newContent =
                            { content | comment = value }
                    in
                    ( { model | currentOperation = Operation.Create newContent }
                    , NoNotification
                    , Cmd.none
                    )

                _ ->
                    ( model, NoNotification, Cmd.none )



{-------------------------
        HELPERS
--------------------------}


convertStringToMaybeString : String -> Maybe String
convertStringToMaybeString stringToConvert =
    case stringToConvert of
        "" ->
            Nothing

        _ ->
            Just stringToConvert


updateAccountingEntry : Operation.AccountingEntry -> String -> String -> Operation.AccountingEntry
updateAccountingEntry accountingEntry field value =
    case field of
        "reference" ->
            { accountingEntry | reference = convertStringToMaybeString value }

        "date" ->
            { accountingEntry | date = convertStringToMaybeString value }

        "amount" ->
            case String.toFloat value of
                Just amount ->
                    { accountingEntry | amount = Operation.AmountField (Just amount) value }

                Nothing ->
                    { accountingEntry | amount = Operation.AmountField Nothing value }

        _ ->
            accountingEntry


operationFormValidator : Validate.Validator ( Form.Field, String ) Operation.Content
operationFormValidator =
    Validate.all
        [ Validate.firstError
            [ Validate.ifBlank .name ( Form.Name, "Merci d'entrer un nom pour cette opération" )
            , Utils.Validators.ifNotAuthorizedString .name
                ( Form.Name
                , "Nom d'opération invalide"
                )
            ]
        , ( Form.Store, "Nom de fournisseur invalide" )
            |> ifNotAuthorizedString .store
        , ( Form.Comment, "Commentaire invalide" )
            |> ifNotAuthorizedString .comment
        ]



{-------------------------
        VIEW
--------------------------}
-- VIEW ALL OPERATIONS OF THE BUDGET IN A TABLE


viewOperations : Model a -> List Operation.Operation -> Html Msg
viewOperations model operations =
    div []
        [ viewAddButton
        , table [ class "table is-budget-tab-content is-striped is-hoverable is-fullwidth" ]
            [ viewOperationsHeaderRow
            , viewOperationsRows operations
            ]
        , viewOperationModal operations model
        ]


viewOperationsHeaderRow : Html Msg
viewOperationsHeaderRow =
    let
        columnNames =
            [ "nom"
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
    thead [] [ tr [] (List.map viewOperationsHeaderCell columnNames) ]


viewOperationsHeaderCell : String -> Html Msg
viewOperationsHeaderCell cellContent =
    th [] [ text cellContent ]


viewOperationsRows : List Operation.Operation -> Html Msg
viewOperationsRows operations =
    tbody [] (List.map viewOperationsRow operations)


viewOperationsRow : Operation.Operation -> Html Msg
viewOperationsRow operation =
    case operation of
        Operation.Validated id content ->
            tr [ onClick <| SelectClicked id ]
                [ th [] [ text content.name ]
                , td [] [ text <| Maybe.withDefault "" content.quotation.reference ]
                , td [] [ text <| Maybe.withDefault "" content.quotation.date ]
                , td [] [ text <| content.quotation.amount.stringValue ]
                , td [] [ text <| Maybe.withDefault "" content.invoice.reference ]
                , td [] [ text <| Maybe.withDefault "" content.invoice.date ]
                , td [] [ text content.invoice.amount.stringValue ]
                , td [] [ text content.store ]
                , td [] [ text content.comment ]
                ]

        _ ->
            emptyDiv



-- SELECT OPERATION TO DISPLAY IN MODAL


viewOperationModal : List Operation.Operation -> Model a -> Html Msg
viewOperationModal operations model =
    case ( model.modal, model.currentOperation ) of
        ( Modal.NoModal, _ ) ->
            emptyDiv

        ( _, Operation.IdOnly id ) ->
            let
                operationToDisplay =
                    Operation.getOperationById id operations
            in
            case operationToDisplay of
                Just content ->
                    displayOperationModal (Just id) content model.formErrors Modal.ReadOnlyModal

                Nothing ->
                    emptyDiv

        ( _, Operation.Validated id content ) ->
            displayOperationModal (Just id) content model.formErrors Modal.ModifyModal

        ( Modal.CreateModal, Operation.Create content ) ->
            displayOperationModal Nothing content model.formErrors Modal.CreateModal

        ( _, _ ) ->
            emptyDiv


emptyDiv : Html Msg
emptyDiv =
    div [] []



-- VIEW OPERATION IN A EDITABLE OR READ-ONLY MODAL


displayOperationModal : Maybe Int -> Operation.Content -> List Form.Error -> Modal.Modal -> Html Msg
displayOperationModal maybeId content formErrors modal =
    div [ class "modal is-operation-modal" ]
        [ div [ class "modal-background" ] []
        , div [ class "modal-card" ]
            [ header [ class "modal-card-head" ]
                (viewOperationHeader maybeId content modal)
            , section [ class "modal-card-body" ]
                [ table [ class "table is-budget-tab-content is-striped is-hoverable is-fullwidth" ]
                    [ viewOperationBody content formErrors modal ]
                ]
            , footer [ class "modal-card-foot" ]
                (viewOperationFooter modal)
            ]
        ]



-- MODAL HEADER


viewOperationHeader : Maybe Int -> Operation.Content -> Modal.Modal -> List (Html Msg)
viewOperationHeader maybeId content modal =
    case ( modal, maybeId ) of
        ( Modal.ReadOnlyModal, Just id ) ->
            [ p [ class "modal-card-title" ] [ text content.name ]
            , button
                [ class "button is-rounded is-success"
                , onClick <| ModifyClicked id content
                ]
                [ span [ class "icon is-small" ]
                    [ i [ class "fas fa-pencil-alt" ] [] ]
                ]
            , button [ class "button is-rounded", onClick CloseModalClicked ]
                [ span [ class "icon is-small" ]
                    [ i [ class "fas fa-times" ] [] ]
                ]
            ]

        ( _, _ ) ->
            [ p [ class "modal-card-title" ] [ text content.name ] ]



-- VIEW OPERATION FIELDS IN MODAL BODY


viewOperationBody : Operation.Content -> List Form.Error -> Modal.Modal -> Html Msg
viewOperationBody content formErrors modal =
    case modal of
        Modal.ReadOnlyModal ->
            viewOperationFields content formErrors viewOperationReadOnly

        Modal.ModifyModal ->
            viewOperationFields content formErrors viewOperationInput

        Modal.CreateModal ->
            viewOperationFields content formErrors viewOperationInput

        _ ->
            emptyDiv


viewOperationFields :
    Operation.Content
    -> List Form.Error
    -> (Form.Field -> List Form.Error -> (String -> Msg) -> String -> Html Msg)
    -> Html Msg
viewOperationFields operation formErrors callback =
    tbody []
        [ tr []
            [ viewLabel "nom"
            , callback Form.Name formErrors SetName operation.name
            , viewLabel ""
            , viewEmptyCell
            ]
        , tr []
            [ viewLabel "ref. devis"
            , Maybe.withDefault "" operation.quotation.reference
                |> callback Form.QuotationReference formErrors SetQuotationReference
            , viewLabel "ref. facture"
            , Maybe.withDefault "" operation.invoice.reference
                |> callback Form.InvoiceReference formErrors SetInvoiceReference
            ]
        , tr []
            [ viewLabel "date devis"
            , Maybe.withDefault "" operation.quotation.date
                |> callback Form.QuotationDate formErrors SetQuotationDate
            , viewLabel "date facture"
            , Maybe.withDefault "" operation.invoice.date
                |> callback Form.InvoiceDate formErrors SetInvoiceDate
            ]
        , tr []
            [ viewLabel "montant devis"
            , operation.quotation.amount.stringValue
                |> callback Form.QuotationAmount formErrors SetQuotationAmount
            , viewLabel "montant facture"
            , operation.invoice.amount.stringValue
                |> callback Form.InvoiceAmount formErrors SetInvoiceAmount
            ]
        , tr []
            [ viewLabel "fournisseur"
            , callback Form.Store formErrors SetStore operation.store
            , viewLabel ""
            , viewEmptyCell
            ]
        , tr []
            [ viewLabel "commentaire"
            , callback Form.Comment formErrors SetComment operation.comment
            , viewLabel ""
            , viewEmptyCell
            ]
        ]


viewLabel : String -> Html Msg
viewLabel label =
    th [] [ text label ]


viewFormErrors : Form.Field -> List Form.Error -> Html msg
viewFormErrors field errors =
    errors
        |> List.filter (\( fieldError, _ ) -> fieldError == field)
        |> List.map (\( _, error ) -> li [] [ text error ])
        |> ul [ class "form-errors" ]


viewEmptyCell : Html Msg
viewEmptyCell =
    td [] []


viewOperationReadOnly : Form.Field -> List Form.Error -> (String -> Msg) -> String -> Html Msg
viewOperationReadOnly field errors msg val =
    td [] [ text val ]


viewOperationInput : Form.Field -> List Form.Error -> (String -> Msg) -> String -> Html Msg
viewOperationInput field errors msg val =
    td []
        [ input [ type_ "text", value val, onInput msg ] []
        , viewFormErrors field errors
        ]



-- MODAL FOOTER


viewOperationFooter : Modal.Modal -> List (Html Msg)
viewOperationFooter modal =
    case modal of
        Modal.ModifyModal ->
            modalSaveCancelDeleteButtons

        Modal.CreateModal ->
            modalSaveAndCancelButtons

        _ ->
            [ emptyDiv ]



-- BUTTON RELATED VIEWS


viewAddButton : Html Msg
viewAddButton =
    button [ class "button is-rounded is-hovered is-pulled-right is-plus-button", onClick AddClicked ]
        [ span [ class "icon is-small" ]
            [ i [ class "fas fa-plus" ] [] ]
        ]


modalSaveAndCancelButtons : List (Html Msg)
modalSaveAndCancelButtons =
    [ successButton "Enregistrer" SaveClicked
    , cancelButton "Annuler" CloseModalClicked
    ]


modalSaveCancelDeleteButtons : List (Html Msg)
modalSaveCancelDeleteButtons =
    [ successButton "Enregistrer" SaveClicked
    , cancelButton "Annuler" CloseModalClicked
    , deleteButton "Supprimer" DeleteClicked
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


deleteButton : String -> Msg -> Html Msg
deleteButton label actionOnClick =
    div [ class "button is-danger is-outlined", onClick actionOnClick ]
        [ span [ class "icon is-small" ]
            [ i [ class "fas fa-times" ] []
            ]
        , span [] [ text label ]
        ]

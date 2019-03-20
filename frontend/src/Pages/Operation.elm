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


reset : Model a -> Model a
reset model =
    { model | modal = Modal.NoModal, currentOperation = Operation.NoOperation, formErrors = [] }


createOperationIn : Model a -> Model a
createOperationIn model =
    { model | modal = Modal.CreateModal, currentOperation = Operation.Create Operation.emptyContent }



{-------------------------
        UPDATE
--------------------------}


type Notification
    = NoNotification
    | SendPutRequest Operation.Operation
    | SendPostRequest Operation.Operation
    | SendDeleteRequest Operation.Operation


type Msg
    = AddClicked
    | CloseModalClicked
    | DeleteClicked
    | ModifyClicked Int Operation.Content
    | SaveClicked
    | SelectClicked Int
    | SetComment String
    | SetIsSubvention Bool String
    | SetInvoiceAmount String
    | SetInvoiceDate String
    | SetInvoiceReference String
    | SetName String
    | SetQuotationAmount String
    | SetQuotationDate String
    | SetQuotationReference String
    | SetStore String


update : Msg -> Model a -> ( Model a, Notification, Cmd Msg )
update msg model =
    case Debug.log "msg" msg of
        AddClicked ->
            ( createOperationIn model
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
                    case Operation.verifyContent content of
                        Ok _ ->
                            ( reset model
                            , SendPutRequest (Operation.Validated id content)
                            , Cmd.none
                            )

                        Err ( e1, errors ) ->
                            ( { model | formErrors = e1 :: errors }
                            , NoNotification
                            , Cmd.none
                            )

                Operation.Create content ->
                    case Operation.verifyContent content of
                        Ok _ ->
                            ( reset model
                            , SendPostRequest (Operation.Create content)
                            , Cmd.none
                            )

                        Err ( e1, errors ) ->
                            ( { model | formErrors = e1 :: errors }
                            , NoNotification
                            , Cmd.none
                            )

                _ ->
                    ( model
                    , NoNotification
                    , Cmd.none
                    )

        SelectClicked operationId ->
            ( { model | modal = Modal.ReadOnlyModal, currentOperation = Operation.IdOnly operationId }
            , NoNotification
            , Cmd.none
            )

        SetComment value ->
            setOperationWith value Operation.asCommentIn model

        SetInvoiceAmount value ->
            setOperationWith value Operation.asInvoiceAmountIn model

        SetInvoiceDate value ->
            setOperationWith value Operation.asInvoiceDateIn model

        SetInvoiceReference value ->
            setOperationWith value Operation.asInvoiceReferenceIn model

        SetIsSubvention value _ ->
            let
                ( quotationCleared, _, _ ) =
                    setOperationWith "" Operation.asClearQuotationIn model
            in
            setOperationWith value Operation.asIsSubventionIn quotationCleared

        SetName value ->
            setOperationWith value Operation.asNameIn model

        SetQuotationAmount value ->
            setOperationWith value Operation.asQuotationAmountIn model

        SetQuotationDate value ->
            setOperationWith value Operation.asQuotationDateIn model

        SetQuotationReference value ->
            setOperationWith value Operation.asQuotationReferenceIn model

        SetStore value ->
            setOperationWith value Operation.asStoreIn model



{-------------------------
        HELPERS
--------------------------}


setOperationWith :
    a
    -> (Operation.Content -> a -> Operation.Content)
    -> Model b
    -> ( Model b, Notification, Cmd Msg )
setOperationWith newValue asInUpdateFunction model =
    case model.currentOperation of
        Operation.Validated id content ->
            ( newValue
                |> asInUpdateFunction content
                |> Operation.Validated id
                |> asCurrentOperationIn model
            , NoNotification
            , Cmd.none
            )

        Operation.Create content ->
            ( newValue
                |> asInUpdateFunction content
                |> Operation.Create
                |> asCurrentOperationIn model
            , NoNotification
            , Cmd.none
            )

        _ ->
            ( model, NoNotification, Cmd.none )


asCurrentOperationIn : Model a -> Operation.Operation -> Model a
asCurrentOperationIn model operation =
    { model | currentOperation = operation }



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
            viewOperationFields content formErrors True

        Modal.ModifyModal ->
            viewOperationFields content formErrors False

        Modal.CreateModal ->
            viewOperationFields content formErrors False

        _ ->
            emptyDiv


viewOperationFields :
    Operation.Content
    -> List Form.Error
    -> Bool
    -> Html Msg
viewOperationFields operation formErrors isReadOnly =
    let
        displayField =
            if isReadOnly then
                viewOperationReadOnly

            else
                viewOperationInput

        displayRadio =
            if isReadOnly then
                viewSubventionValue

            else
                viewSubventionRadio
    in
    tbody []
        [ tr []
            [ viewLabel "nom"
            , displayField Form.Name formErrors SetName operation.name
            , viewLabel "type d'opération"
            , displayRadio operation
            ]
        , viewQuotationInvoiceReference operation formErrors displayField
        , viewQuotationInvoiceDate operation formErrors displayField
        , viewQuotationInvoiceAmount operation formErrors displayField
        , tr []
            [ viewLabel "fournisseur"
            , displayField Form.Store formErrors SetStore operation.store
            , viewLabel ""
            , viewEmptyCell
            ]
        , tr []
            [ viewLabel "commentaire"
            , displayField Form.Comment formErrors SetComment operation.comment
            , viewLabel ""
            , viewEmptyCell
            ]
        ]


viewQuotationInvoiceReference :
    Operation.Content
    -> List Form.Error
    -> (Form.Field -> List Form.Error -> (String -> Msg) -> String -> Html Msg)
    -> Html Msg
viewQuotationInvoiceReference operation errors displayField =
    if not operation.isSubvention then
        tr []
            [ viewLabel "ref. devis"
            , Maybe.withDefault "" operation.quotation.reference
                |> displayField Form.QuotationReference errors SetQuotationReference
            , viewLabel "ref. facture"
            , Maybe.withDefault "" operation.invoice.reference
                |> displayField Form.InvoiceReference errors SetInvoiceReference
            ]

    else
        tr []
            [ viewLabel "ref. subvention"
            , Maybe.withDefault "" operation.invoice.reference
                |> displayField Form.InvoiceReference errors SetInvoiceReference
            ]


viewQuotationInvoiceDate :
    Operation.Content
    -> List Form.Error
    -> (Form.Field -> List Form.Error -> (String -> Msg) -> String -> Html Msg)
    -> Html Msg
viewQuotationInvoiceDate operation errors displayField =
    if not operation.isSubvention then
        tr []
            [ viewLabel "date devis"
            , Maybe.withDefault "" operation.quotation.date
                |> displayField Form.QuotationDate errors SetQuotationDate
            , viewLabel "date facture"
            , Maybe.withDefault "" operation.invoice.date
                |> displayField Form.InvoiceDate errors SetInvoiceDate
            ]

    else
        tr []
            [ viewLabel "date subvention"
            , Maybe.withDefault "" operation.invoice.date
                |> displayField Form.InvoiceDate errors SetInvoiceDate
            ]


viewQuotationInvoiceAmount :
    Operation.Content
    -> List Form.Error
    -> (Form.Field -> List Form.Error -> (String -> Msg) -> String -> Html Msg)
    -> Html Msg
viewQuotationInvoiceAmount operation errors displayField =
    if not operation.isSubvention then
        tr []
            [ viewLabel "montant devis"
            , operation.quotation.amount.stringValue
                |> displayField Form.QuotationAmount errors SetQuotationAmount
            , viewLabel "montant facture"
            , operation.invoice.amount.stringValue
                |> displayField Form.InvoiceAmount errors SetInvoiceAmount
            ]

    else
        tr []
            [ viewLabel "montant subvention"
            , operation.invoice.amount.stringValue
                |> displayField Form.InvoiceAmount errors SetInvoiceAmount
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


viewSubventionValue : Operation.Content -> Html Msg
viewSubventionValue operation =
    if operation.isSubvention then
        td [] [ text "subvention" ]

    else
        td [] [ text "devis/facture" ]


viewSubventionRadio : Operation.Content -> Html Msg
viewSubventionRadio operation =
    td []
        [ radioInput "subvention" (SetIsSubvention False) (not operation.isSubvention)
        , text "devis/facture"
        , radioInput "subvention" (SetIsSubvention True) operation.isSubvention
        , text "subvention"
        ]


radioInput : String -> (String -> Msg) -> Bool -> Html Msg
radioInput name_ msg isChecked =
    input [ type_ "radio", name name_, onInput msg, checked isChecked ] []



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

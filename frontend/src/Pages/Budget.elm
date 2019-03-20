module Pages.Budget exposing
    ( Model
    , Msg
    , Notification(..)
    , addNewBudget
    , setBudget
    , update
    , viewInfo
    , viewModal
    )

import Data.Budget as Budget
import Data.Form as Form
import Data.Modal as Modal
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)



{-------------------------
        MODEL
--------------------------}


type alias Model a =
    { a
        | currentBudget : Budget.Budget
        , modal : Modal.Modal
        , possibleBudgetTypes : List String
        , possibleRecipients : List String
        , possibleCreditors : List String
        , formErrors : List Form.Error
    }


addNewBudget : Model a -> Model a
addNewBudget model =
    let
        newBudget =
            Budget.create model.possibleBudgetTypes model.possibleCreditors model.possibleRecipients
    in
    { model | currentBudget = newBudget, modal = Modal.CreateModal }


setBudget : Budget.Budget -> Model a -> Model a
setBudget budget model =
    { model | currentBudget = budget }


asCurrentBudgetIn : Model a -> Budget.Budget -> Model a
asCurrentBudgetIn model budget =
    setBudget budget model



{-------------------------
        UPDATE
--------------------------}


type Notification
    = GetBudgetTypes
    | NoNotification
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


update : Msg -> Model a -> ( Model a, Notification, Cmd Msg )
update msg model =
    case msg of
        AddClicked ->
            ( addNewBudget model
            , NoNotification
            , Cmd.none
            )

        BudgetTypeSelected newType ->
            setInfoWith newType Budget.asBudgetTypeIn model

        CloseModalClicked ->
            case model.currentBudget of
                Budget.Validated existingBudget ->
                    ( { model | modal = Modal.NoModal }
                    , ReloadBudget existingBudget.id
                    , Cmd.none
                    )

                Budget.Create info ->
                    ( { model | currentBudget = Budget.NoBudget, modal = Modal.NoModal }
                    , ReloadHome
                    , Cmd.none
                    )

                _ ->
                    ( { model | modal = Modal.NoModal }
                    , NoNotification
                    , Cmd.none
                    )

        ModifyClicked ->
            ( { model | modal = Modal.ModifyModal }
            , GetBudgetTypes
            , Cmd.none
            )

        SaveClicked ->
            case model.currentBudget of
                Budget.Validated existingBudget ->
                    case Budget.verifyInfo existingBudget.info of
                        Ok _ ->
                            let
                                updatedBudget =
                                    Budget.Update { id = existingBudget.id, info = existingBudget.info }
                            in
                            ( { model | modal = Modal.NoModal, currentBudget = updatedBudget }
                            , SendPutRequest
                            , Cmd.none
                            )

                        Err ( e1, errors ) ->
                            ( { model | formErrors = e1 :: errors }
                            , NoNotification
                            , Cmd.none
                            )

                Budget.Create info ->
                    ( { model | modal = Modal.NoModal }
                    , SendPostRequest
                    , Cmd.none
                    )

                _ ->
                    ( { model | modal = Modal.NoModal, currentBudget = Budget.NoBudget }
                    , NoNotification
                    , Cmd.none
                    )

        SetComment newValue ->
            setInfoWith newValue Budget.asCommentIn model

        SetCreditor newValue ->
            setInfoWith newValue Budget.asCreditorIn model

        SetName newValue ->
            setInfoWith newValue Budget.asInfoNameIn model

        SetRecipient newValue ->
            setInfoWith newValue Budget.asRecipientIn model

        SetReference newValue ->
            setInfoWith newValue Budget.asReferenceIn model


setInfoWith :
    String
    -> (Budget.Info -> String -> Budget.Info)
    -> Model a
    -> ( Model a, Notification, Cmd Msg )
setInfoWith newValue asInUpdateFunction model =
    case model.currentBudget of
        Budget.Validated existingBudget ->
            ( newValue
                |> asInUpdateFunction existingBudget.info
                |> Budget.asInfoIn model.currentBudget
                |> asCurrentBudgetIn model
            , NoNotification
            , Cmd.none
            )

        Budget.Create info ->
            ( newValue
                |> asInUpdateFunction info
                |> Budget.asInfoIn model.currentBudget
                |> asCurrentBudgetIn model
            , NoNotification
            , Cmd.none
            )

        _ ->
            ( model, NoNotification, Cmd.none )



{-------------------------
        VIEW
--------------------------}
-- DETAILS PAGE


viewInfo : Model a -> Html Msg
viewInfo model =
    case model.currentBudget of
        Budget.Validated existingBudget ->
            div []
                [ viewModifyButton
                , table [ class "table is-budget-tab-content is-striped is-hoverable is-fullwidth" ]
                    [ viewInfoRows existingBudget.info ]
                , viewModal model
                ]

        Budget.Update budget ->
            div []
                [ viewModifyButton
                , table [ class "table is-budget-tab-content is-striped is-hoverable is-fullwidth" ]
                    [ viewInfoRows budget.info ]
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


viewInfoRows : Budget.Info -> Html Msg
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



-- MODAL PAGE


viewModal : Model a -> Html Msg
viewModal model =
    case ( model.modal, model.currentBudget ) of
        ( Modal.NoModal, _ ) ->
            emptyDiv

        ( _, Budget.Validated existingBudget ) ->
            displayModal model existingBudget.info Modal.ModifyModal

        ( Modal.CreateModal, Budget.Create info ) ->
            displayModal model info Modal.CreateModal

        ( _, _ ) ->
            emptyDiv


emptyDiv : Html Msg
emptyDiv =
    div [] []


displayModal : Model a -> Budget.Info -> Modal.Modal -> Html Msg
displayModal model info modal =
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


viewModalHeader : Budget.Info -> List (Html Msg)
viewModalHeader info =
    [ p [ class "modal-card-title" ] [ text info.name ] ]


viewModalBody : Model a -> Budget.Info -> Modal.Modal -> Html Msg
viewModalBody model info modal =
    case modal of
        Modal.ModifyModal ->
            viewFields model info viewInputFormat

        Modal.CreateModal ->
            viewFields model info viewInputFormat

        _ ->
            emptyDiv


viewFields : Model a -> Budget.Info -> ((String -> Msg) -> String -> Html Msg) -> Html Msg
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
            , viewSelectType model BudgetTypeSelected info.budgetType model.possibleBudgetTypes
            ]
        , tr []
            [ viewLabel "bénéficiaire"
            , viewSelectType model SetRecipient info.recipient model.possibleRecipients
            ]
        , tr []
            [ viewLabel "créditeur"
            , viewSelectType model SetCreditor info.creditor model.possibleCreditors
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


viewSelectType : Model a -> (String -> Msg) -> String -> List String -> Html Msg
viewSelectType model msg currentValue valueList =
    td []
        [ div [ class "select" ]
            [ select [ onInput msg ]
                (List.map
                    (\x ->
                        if x == currentValue then
                            selectedTypeOption x

                        else
                            typeOption x
                    )
                    valueList
                )
            ]
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

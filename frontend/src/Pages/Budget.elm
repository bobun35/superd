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

import Data.Budget exposing (..)
import Data.Modal as Modal
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)



{-------------------------
        MODEL
--------------------------}


type alias Model a =
    { a
        | currentBudget : Budget
        , modal : Modal.Modal
        , possibleBudgetTypes : List String
        , possibleRecipients : List String
        , possibleCreditors : List String
    }


addNewBudget : Model a -> Model a
addNewBudget model =
    let
        newBudget =
            Data.Budget.create model.possibleBudgetTypes model.possibleCreditors model.possibleRecipients
    in
    { model | currentBudget = newBudget, modal = Modal.CreateModal }


setBudget : Budget -> Model a -> Model a
setBudget budget model =
    { model | currentBudget = budget }


asCurrentBudgetIn : Model a -> Budget -> Model a
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
            setInfoWith newType asBudgetTypeIn model

        CloseModalClicked ->
            case model.currentBudget of
                Validated existingBudget ->
                    ( { model | modal = Modal.NoModal }
                    , ReloadBudget existingBudget.id
                    , Cmd.none
                    )

                Create info ->
                    ( { model | currentBudget = NoBudget, modal = Modal.NoModal }
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
                Validated existingBudget ->
                    let
                        updatedBudget =
                            Update { id = existingBudget.id, info = existingBudget.info }
                    in
                    ( { model | modal = Modal.NoModal, currentBudget = updatedBudget }
                    , SendPutRequest
                    , Cmd.none
                    )

                Create info ->
                    ( { model | modal = Modal.NoModal }
                    , SendPostRequest
                    , Cmd.none
                    )

                _ ->
                    ( { model | modal = Modal.NoModal, currentBudget = NoBudget }
                    , NoNotification
                    , Cmd.none
                    )

        SetComment newValue ->
            setInfoWith newValue asCommentIn model

        SetCreditor newValue ->
            setInfoWith newValue asCreditorIn model

        SetName newValue ->
            setInfoWith newValue asInfoNameIn model

        SetRecipient newValue ->
            setInfoWith newValue asRecipientIn model

        SetReference newValue ->
            setInfoWith newValue asReferenceIn model


setInfoWith : String -> (Info -> String -> Info) -> Model a -> ( Model a, Notification, Cmd Msg )
setInfoWith newValue asInUpdateFunction model =
    case model.currentBudget of
        Validated existingBudget ->
            ( newValue
                |> asInUpdateFunction existingBudget.info
                |> asInfoIn model.currentBudget
                |> asCurrentBudgetIn model
            , NoNotification
            , Cmd.none
            )

        Create info ->
            ( newValue
                |> asInUpdateFunction info
                |> asInfoIn model.currentBudget
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
        Validated existingBudget ->
            div []
                [ viewModifyButton
                , table [ class "table is-budget-tab-content is-striped is-hoverable is-fullwidth" ]
                    [ viewInfoRows existingBudget.info ]
                , viewModal model
                ]

        Update budget ->
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



-- MODAL PAGE


viewModal : Model a -> Html Msg
viewModal model =
    case ( model.modal, model.currentBudget ) of
        ( Modal.NoModal, _ ) ->
            emptyDiv

        ( _, Validated existingBudget ) ->
            displayModal model existingBudget.info Modal.ModifyModal

        ( Modal.CreateModal, Create info ) ->
            displayModal model info Modal.CreateModal

        ( _, _ ) ->
            emptyDiv


emptyDiv : Html Msg
emptyDiv =
    div [] []


displayModal : Model a -> Info -> Modal.Modal -> Html Msg
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


viewModalHeader : Info -> List (Html Msg)
viewModalHeader info =
    [ p [ class "modal-card-title" ] [ text info.name ] ]


viewModalBody : Model a -> Info -> Modal.Modal -> Html Msg
viewModalBody model info modal =
    case modal of
        Modal.ModifyModal ->
            viewFields model info viewInputFormat

        Modal.CreateModal ->
            viewFields model info viewInputFormat

        _ ->
            emptyDiv


viewFields : Model a -> Info -> ((String -> Msg) -> String -> Html Msg) -> Html Msg
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

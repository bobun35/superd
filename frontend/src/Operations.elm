module Operations exposing (Operation, OperationType, Quotation, Invoice, Modal(..), Msg, Model, Status(..), update, initModel, operationDecoder, viewAllOperationsTable, displayOperationModal)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Json.Decode exposing (Decoder)
import Json.Decode.Extra


{-------------------------
        MODEL
--------------------------}
type alias Model =
    { status: Status 
    , modal: Modal }

initModel =
    Model NoOperation NoModal


{-------------------------
        TYPES
--------------------------}

type Status
    = NoOperation
    | IdOnly Int
    | Validated Operation

type alias Operation =
    { id: Int
    , name: String
    , operationType: OperationType
    , store: String
    , comment: Maybe String
    , quotation: Quotation
    , invoice: Invoice
    }

type OperationType 
    = Credit
    | Debit

type alias Quotation =
    { quotationReference: Maybe String
    , quotationDate: Maybe String
    , quotationAmount: Maybe Int
    }

type alias Invoice =
    { invoiceReference: Maybe String
    , invoiceDate: Maybe String
    , invoiceAmount: Maybe Int
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

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectOperationClicked operationId ->
            ( { model | modal = DisplayOperationModal, status = IdOnly operationId }
            , Cmd.none )
        
        CloseOperationModalClicked ->
            ( { model | modal = NoModal, status = NoOperation }
            , Cmd.none)
        
        ModifyOperationClicked operation ->
            ( { model | modal = ModifyOperationModal, status = Validated operation }
            , Cmd.none )


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
                (Json.Decode.field "quotationAmount" (Json.Decode.nullable Json.Decode.int)))
        |> Json.Decode.Extra.andMap (Json.Decode.map3 Invoice 
                (Json.Decode.field "invoice" (Json.Decode.nullable Json.Decode.string)) 
                (Json.Decode.field "invoiceDate" (Json.Decode.nullable dateDecoder))
                (Json.Decode.field "invoiceAmount" (Json.Decode.nullable Json.Decode.int)))

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


{-------------------------
        VIEW
--------------------------}

-- VIEW ALL OPERATIONS IN A TABLE
viewAllOperationsTable: List Operation -> Html Msg
viewAllOperationsTable operations =
    table [ class "table is-budget-tab-content is-striped is-hoverable is-fullwidth"]
          [ viewAllOperationsHeaderRow 
          , viewAllOperationsRows operations ]

viewAllOperationsHeaderRow: Html Msg
viewAllOperationsHeaderRow =
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
        thead [] [ tr [] (List.map viewAllOperationsHeaderCell columnNames)]

viewAllOperationsHeaderCell: String -> Html Msg
viewAllOperationsHeaderCell cellContent =
    th [] [text cellContent]

viewAllOperationsRows: List Operation -> Html Msg
viewAllOperationsRows operations =
    tbody [] (List.map viewAllOperationsRow operations)

viewAllOperationsRow: Operation -> Html Msg
viewAllOperationsRow operation =
        tr [ onClick <| SelectOperationClicked operation.id ] [ th [] [text operation.name]
                , td [] [text <| Maybe.withDefault "" operation.quotation.quotationReference ]
                , td [] [text <| Maybe.withDefault "" operation.quotation.quotationDate ]
                , td [] [text <| Maybe.withDefault "" <| maybeFloatToMaybeString <| centsToEuros operation.quotation.quotationAmount ]
                , td [] [text <| Maybe.withDefault "" operation.invoice.invoiceReference ]
                , td [] [text <| Maybe.withDefault "" operation.invoice.invoiceDate ]
                , td [] [text <| Maybe.withDefault "" <| maybeFloatToMaybeString <| centsToEuros operation.invoice.invoiceAmount ]
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


-- VIEW OPERATION IN A MODAL
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

emptyDiv : Html Msg
emptyDiv = div [] []

-- according to the type of the modal use readOnly or Input fields to view operation details
viewOperationFields: Operation -> (String -> String -> Html Msg) -> Html Msg
viewOperationFields operation callback =
        tbody [] [callback "nom" operation.name
                , callback "n° devis" <| Maybe.withDefault "" operation.quotation.quotationReference
                , callback "date du devis" <| Maybe.withDefault "" operation.quotation.quotationDate
                , callback "montant du devis" <| Maybe.withDefault "" <| maybeFloatToMaybeString <| centsToEuros operation.quotation.quotationAmount
                , callback "n° facture" <| Maybe.withDefault "" operation.invoice.invoiceReference
                , callback "date facture" <| Maybe.withDefault "" operation.invoice.invoiceDate
                , callback "montant facture" <| Maybe.withDefault "" <| maybeFloatToMaybeString <| centsToEuros operation.invoice.invoiceAmount
                , callback "fournisseur" operation.store
                , callback "commentaire" <| Maybe.withDefault "" operation.comment
            ]

viewOperationReadOnly: String -> String -> Html Msg
viewOperationReadOnly label val =
    tr [] [th [] [text label]
          , td [] [text val]
          ]

viewOperationInput: String -> String -> Html Msg
viewOperationInput label val =
    tr [] [th [] [text label]
          , td [] [input [ type_ "text", value val] []]
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




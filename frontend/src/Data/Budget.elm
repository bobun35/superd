module Data.Budget exposing
    ( Budget(..)
    , Info
    , asBudgetTypeIn
    , asCommentIn
    , asCreditorIn
    , asInfoIn
    , asInfoNameIn
    , asRecipientIn
    , asReferenceIn
    , budgetDecoder
    , budgetEncoder
    , create
    , getId
    , getName
    , getOperations
    , getRealRemaining
    , getVirtualRemaining
    , idDecoder
    , init
    , isValid
    , itemsDecoder
    , verifyInfo
    )

import Data.Form as Form
import Data.Operation
import Json.Decode exposing (Decoder)
import Json.Decode.Extra
import Json.Decode.Pipeline
import Json.Encode
import String.Verify
import Utils.Validators as Utils
import Verify exposing (Validator)


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
    , operations : List Data.Operation.Operation
    }


type alias Info =
    { name : String
    , reference : String
    , budgetType : String
    , recipient : String
    , creditor : String
    , comment : String
    }



{-------------------------
    INIT - DEFAULT
--------------------------}


init : Budget
init =
    NoBudget


create : List String -> List String -> List String -> Budget
create possibleBudgetTypes possibleCreditors possibleRecipients =
    defaultInfo possibleBudgetTypes possibleCreditors possibleRecipients
        |> Create


defaultInfo : List String -> List String -> List String -> Info
defaultInfo possibleBudgetTypes possibleCreditors possibleRecipients =
    let
        defaultBudgetType =
            Maybe.withDefault "" <| List.head possibleBudgetTypes

        defaultCreditor =
            Maybe.withDefault "" <| List.head possibleCreditors

        defaultRecipient =
            Maybe.withDefault "" <| List.head possibleRecipients
    in
    { name = ""
    , reference = ""
    , budgetType = defaultBudgetType
    , recipient = defaultRecipient
    , creditor = defaultCreditor
    , comment = ""
    }



{-------------------------
      VALIDATION
--------------------------}


isValid : Budget -> Bool
isValid budget =
    case budget of
        Validated _ ->
            True

        Update _ ->
            True

        _ ->
            False



{--------------------------------
    GETTERS - SETTERS  BUDGET
---------------------------------}


getId : Budget -> Maybe Int
getId budget =
    case budget of
        Validated existingBudget ->
            Just existingBudget.id

        Update updatedBudget ->
            Just updatedBudget.id

        _ ->
            Nothing


getOperations : Budget -> List Data.Operation.Operation
getOperations budget =
    case budget of
        Validated existingBudget ->
            existingBudget.operations

        _ ->
            []


getName : Budget -> Maybe String
getName budget =
    case budget of
        Validated existingBudget ->
            Just existingBudget.info.name

        _ ->
            Nothing


getRealRemaining : Budget -> Maybe Float
getRealRemaining budget =
    case budget of
        Validated existingBudget ->
            Just existingBudget.realRemaining

        _ ->
            Nothing


getVirtualRemaining : Budget -> Maybe Float
getVirtualRemaining budget =
    case budget of
        Validated existingBudget ->
            Just existingBudget.virtualRemaining

        _ ->
            Nothing



{--------------------------------
    GETTERS - SETTERS  INFO
---------------------------------}


asInfoIn : Budget -> Info -> Budget
asInfoIn budget newInfo =
    case budget of
        Validated existingBudget ->
            Validated { existingBudget | info = newInfo }

        Create info ->
            Create newInfo

        _ ->
            budget


setInfoName : String -> Info -> Info
setInfoName newName info =
    { info | name = newName }


asInfoNameIn : Info -> String -> Info
asInfoNameIn info newName =
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



{-------------------------
     DECODER BUDGET
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
        |> Json.Decode.Pipeline.required "operations" (Json.Decode.list Data.Operation.operationDecoder)
        |> Json.Decode.Pipeline.resolve


toDecoder : Int -> String -> String -> String -> String -> String -> String -> Float -> Float -> List Data.Operation.Operation -> Decoder Budget
toDecoder id name reference budgetType recipient creditor comment real virtual operations =
    ExistingBudget id
        (Info name reference budgetType recipient creditor comment)
        real
        virtual
        operations
        |> Validated
        |> Json.Decode.succeed



{-------------------------
     OTHER DECODERS
--------------------------}


itemsDecoder : Decoder (List String)
itemsDecoder =
    Json.Decode.field "items" (Json.Decode.list itemDecoder)


itemDecoder : Decoder String
itemDecoder =
    Json.Decode.field "name" Json.Decode.string


idDecoder : Decoder Int
idDecoder =
    Json.Decode.field "id" Json.Decode.int



{-------------------------
        ENCODER
--------------------------}


budgetEncoder : Budget -> Json.Encode.Value
budgetEncoder budget =
    case budget of
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
        VERIFIER
--------------------------}


verifyInfo : Verify.Validator Form.Error Info Info
verifyInfo =
    Verify.validate Info
        |> Verify.verify identity verifyName
        |> Verify.verify identity verifyReference
        |> Verify.verify identity verifyBudgetType
        |> Verify.verify identity verifyRecipient
        |> Verify.verify identity verifyCreditor
        |> Verify.verify identity verifyComment


verifyName : Verify.Validator Form.Error { a | name : String } String
verifyName =
    Verify.validate identity
        |> Verify.verify .name (String.Verify.notBlank ( Form.Name, "donnez un nom à ce budget" ))
        |> Verify.compose (Utils.verifyString ( Form.Name, "nom invalide" ))


verifyReference : Verify.Validator Form.Error { a | reference : String } String
verifyReference =
    Verify.validate identity
        |> Verify.verify .reference (String.Verify.notBlank ( Form.Reference, "entrez une référence" ))
        |> Verify.compose (Utils.verifyString ( Form.Reference, "référence invalide" ))


verifyBudgetType : Verify.Validator Form.Error { a | budgetType : String } String
verifyBudgetType =
    Verify.validate identity
        |> Verify.verify .budgetType (String.Verify.notBlank ( Form.Type, "sélectionnez un type de budget" ))
        |> Verify.compose (Utils.verifyString ( Form.Type, "type de budget invalide" ))


verifyRecipient : Verify.Validator Form.Error { a | recipient : String } String
verifyRecipient =
    Verify.validate identity
        |> Verify.verify .recipient (String.Verify.notBlank ( Form.Recipient, "sélectionnez un bénéficiaire" ))
        |> Verify.compose (Utils.verifyString ( Form.Recipient, "bénéficiaire du budget invalide" ))


verifyCreditor : Verify.Validator Form.Error { a | creditor : String } String
verifyCreditor =
    Verify.validate identity
        |> Verify.verify .creditor (String.Verify.notBlank ( Form.Creditor, "entrez un créditeur" ))
        |> Verify.compose (Utils.verifyString ( Form.Creditor, "créditeur du budget invalide" ))


verifyComment : Verify.Validator Form.Error { a | comment : String } String
verifyComment =
    Verify.validate identity
        |> Verify.verify .comment (Utils.verifyString ( Form.Comment, "commentaire invalide" ))

module Data.Operation exposing
    ( AccountingEntry
    , AmountField
    , Content
    , Operation(..)
    , asCommentIn
    , asInvoiceAmountIn
    , asInvoiceDateIn
    , asInvoiceReferenceIn
    , asNameIn
    , asQuotationAmountIn
    , asQuotationDateIn
    , asQuotationReferenceIn
    , asStoreIn
    , emptyContent
    , getOperationById
    , idEncoder
    , init
    , operationDecoder
    , operationEncoder
    , verifyContent
    , verifyName
    , verifyQuotation
    , verifyStore
    )

import Data.Form as Form
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline
import Json.Encode
import Maybe.Verify
import Regex exposing (Regex)
import String.Verify
import Verify exposing (Validator)



{-------------------------
        TYPES
--------------------------}


type Operation
    = NoOperation
    | IdOnly Int
    | Validated Int Content
    | Create Content


type alias Content =
    { name : String
    , store : String
    , comment : String
    , quotation : AccountingEntry
    , invoice : AccountingEntry
    , isSubvention : Bool
    }


type alias AccountingEntry =
    { reference : Maybe String
    , date : Maybe String
    , amount : AmountField
    }


type alias AmountField =
    { value : Maybe Float
    , stringValue : String
    }


type alias VerifiedAccountingEntry =
    { reference : String
    , date : String
    , amount : Float
    }



{----------------------------
    INIT AND DEFAULT
-----------------------------}


emptyContent =
    { name = ""
    , store = ""
    , comment = ""
    , quotation = emptyAccountingEntry
    , invoice = emptyAccountingEntry
    , isSubvention = False
    }


emptyAccountingEntry =
    { reference = Nothing
    , date = Nothing
    , amount = AmountField Nothing ""
    }


init : Operation
init =
    NoOperation



{----------------------------
    GETTERS AND SETTERS
-----------------------------}


getOperationById : Int -> List Operation -> Maybe Content
getOperationById operationId operations =
    List.filterMap (isSearchedOperation operationId) operations
        |> List.map (\( _, content ) -> content)
        |> List.head


isSearchedOperation : Int -> Operation -> Maybe ( Int, Content )
isSearchedOperation operationId element =
    case element of
        Validated id content ->
            if id == operationId then
                Just ( id, content )

            else
                Nothing

        _ ->
            Nothing


asCommentIn : Content -> String -> Content
asCommentIn content newValue =
    { content | comment = newValue }


asNameIn : Content -> String -> Content
asNameIn content newValue =
    { content | name = newValue }


asStoreIn : Content -> String -> Content
asStoreIn content newValue =
    { content | store = newValue }


asInvoiceAmountIn : Content -> String -> Content
asInvoiceAmountIn content value =
    { content | invoice = setInvoiceAmount content.invoice value }


setInvoiceAmount : AccountingEntry -> String -> AccountingEntry
setInvoiceAmount accountingEntry amountAsString =
    case String.toFloat amountAsString of
        Just amount ->
            { accountingEntry | amount = AmountField (Just amount) amountAsString }

        Nothing ->
            { accountingEntry | amount = AmountField Nothing amountAsString }


asInvoiceDateIn : Content -> String -> Content
asInvoiceDateIn content value =
    { content | invoice = setInvoiceDate content.invoice value }


setInvoiceDate : AccountingEntry -> String -> AccountingEntry
setInvoiceDate accountingEntry date =
    { accountingEntry | date = convertStringToMaybeString date }


convertStringToMaybeString : String -> Maybe String
convertStringToMaybeString stringToConvert =
    case stringToConvert of
        "" ->
            Nothing

        _ ->
            Just stringToConvert


asInvoiceReferenceIn : Content -> String -> Content
asInvoiceReferenceIn content value =
    { content | invoice = setInvoiceReference content.invoice value }


setInvoiceReference : AccountingEntry -> String -> AccountingEntry
setInvoiceReference accountingEntry reference =
    { accountingEntry | reference = convertStringToMaybeString reference }


asQuotationAmountIn : Content -> String -> Content
asQuotationAmountIn content value =
    { content | quotation = setQuotationAmount content.quotation value }


setQuotationAmount : AccountingEntry -> String -> AccountingEntry
setQuotationAmount accountingEntry amountAsString =
    case String.toFloat amountAsString of
        Just amount ->
            { accountingEntry | amount = AmountField (Just amount) amountAsString }

        Nothing ->
            { accountingEntry | amount = AmountField Nothing amountAsString }


asQuotationDateIn : Content -> String -> Content
asQuotationDateIn content value =
    { content | quotation = setQuotationDate content.quotation value }


setQuotationDate : AccountingEntry -> String -> AccountingEntry
setQuotationDate accountingEntry date =
    { accountingEntry | date = convertStringToMaybeString date }


asQuotationReferenceIn : Content -> String -> Content
asQuotationReferenceIn content value =
    { content | quotation = setQuotationReference content.quotation value }


setQuotationReference : AccountingEntry -> String -> AccountingEntry
setQuotationReference accountingEntry reference =
    { accountingEntry | reference = convertStringToMaybeString reference }



{-------------------------
        DECODER
--------------------------}


operationDecoder : Decoder Operation
operationDecoder =
    Json.Decode.succeed toDecoder
        |> Json.Decode.Pipeline.required "id" Json.Decode.int
        |> Json.Decode.Pipeline.required "name" Json.Decode.string
        |> Json.Decode.Pipeline.required "store" Json.Decode.string
        |> Json.Decode.Pipeline.required "comment" Json.Decode.string
        |> Json.Decode.Pipeline.optional "quotation" (Json.Decode.nullable Json.Decode.string) Nothing
        |> Json.Decode.Pipeline.optional "quotationDate" (Json.Decode.nullable dateDecoder) Nothing
        |> Json.Decode.Pipeline.custom (Json.Decode.field "quotationAmount" amountDecoder)
        |> Json.Decode.Pipeline.optional "invoice" (Json.Decode.nullable Json.Decode.string) Nothing
        |> Json.Decode.Pipeline.optional "invoiceDate" (Json.Decode.nullable dateDecoder) Nothing
        |> Json.Decode.Pipeline.custom (Json.Decode.field "invoiceAmount" amountDecoder)
        |> Json.Decode.Pipeline.custom (Json.Decode.field "invoiceAmount" subventionDecoder)
        |> Json.Decode.Pipeline.resolve


toDecoder :
    Int
    -> String
    -> String
    -> String
    -> Maybe String
    -> Maybe String
    -> AmountField
    -> Maybe String
    -> Maybe String
    -> AmountField
    -> Bool
    -> Decoder Operation
toDecoder id name store comment quotationReference quotationDate quotationAmount reference date amount isSubvention =
    let
        quotation =
            AccountingEntry quotationReference quotationDate quotationAmount

        invoice =
            AccountingEntry reference date amount
    in
    Json.Decode.succeed <| Validated id <| Content name store comment quotation invoice isSubvention


dateDecoder : Decoder String
dateDecoder =
    Json.Decode.succeed toDateString
        |> Json.Decode.Pipeline.required "dayOfMonth" Json.Decode.int
        |> Json.Decode.Pipeline.required "monthOfYear" Json.Decode.int
        |> Json.Decode.Pipeline.required "yearOfEra" Json.Decode.int


toDateString : Int -> Int -> Int -> String
toDateString day month year =
    String.join "/"
        [ String.fromInt day
        , String.fromInt month
        , String.fromInt year
        ]


amountDecoder : Decoder AmountField
amountDecoder =
    Json.Decode.nullable Json.Decode.int
        |> Json.Decode.andThen amountFieldDecoder


amountFieldDecoder : Maybe Int -> Decoder AmountField
amountFieldDecoder maybeAmount =
    case centsToEuros maybeAmount of
        Just amount ->
            Json.Decode.succeed <| AmountField (Just amount) (String.fromFloat amount)

        Nothing ->
            Json.Decode.succeed <| AmountField Nothing ""


centsToEuros : Maybe Int -> Maybe Float
centsToEuros maybeAmount =
    case maybeAmount of
        Just amount ->
            Just (toFloat amount / 100)

        Nothing ->
            Nothing


subventionDecoder : Decoder Bool
subventionDecoder =
    Json.Decode.nullable Json.Decode.int
        |> Json.Decode.andThen subventionFieldDecoder


subventionFieldDecoder : Maybe Int -> Decoder Bool
subventionFieldDecoder maybeAmount =
    case maybeAmount of
        Just amount ->
            if amount > 0 then
                Json.Decode.succeed True

            else
                Json.Decode.succeed False

        Nothing ->
            Json.Decode.succeed False



{-------------------------
        ENCODER
--------------------------}


operationEncoder : Operation -> Json.Encode.Value
operationEncoder operation =
    case operation of
        Validated id content ->
            Json.Encode.object
                [ ( "id", Json.Encode.int id )
                , ( "name", Json.Encode.string content.name )
                , ( "store", Json.Encode.string content.store )
                , ( "comment", Json.Encode.string content.comment )
                , ( "quotation", encodeMaybeString content.quotation.reference )
                , ( "quotationDate", encodeMaybeString content.quotation.date )
                , ( "quotationAmount", encodeAmount content.quotation.amount )
                , ( "invoice", encodeMaybeString content.invoice.reference )
                , ( "invoiceDate", encodeMaybeString content.invoice.date )
                , ( "invoiceAmount", encodeAmount content.invoice.amount )
                ]

        Create content ->
            Json.Encode.object
                [ ( "name", Json.Encode.string content.name )
                , ( "store", Json.Encode.string content.store )
                , ( "comment", Json.Encode.string content.comment )
                , ( "quotation", encodeMaybeString content.quotation.reference )
                , ( "quotationDate", encodeMaybeString content.quotation.date )
                , ( "quotationAmount", encodeAmount content.quotation.amount )
                , ( "invoice", encodeMaybeString content.invoice.reference )
                , ( "invoiceDate", encodeMaybeString content.invoice.date )
                , ( "invoiceAmount", encodeAmount content.invoice.amount )
                ]

        _ ->
            Json.Encode.null


encodeMaybeString : Maybe String -> Json.Encode.Value
encodeMaybeString maybeString =
    case maybeString of
        Just value ->
            Json.Encode.string value

        Nothing ->
            Json.Encode.null


encodeAmount : AmountField -> Json.Encode.Value
encodeAmount amountField =
    encodeMaybeFloat amountField.value


encodeMaybeFloat : Maybe Float -> Json.Encode.Value
encodeMaybeFloat maybeFloat =
    case maybeFloat of
        Just value ->
            Json.Encode.int <| euroToCents value

        Nothing ->
            Json.Encode.null


euroToCents : Float -> Int
euroToCents floatAmount =
    round <| floatAmount * 100


idEncoder : Operation -> Json.Encode.Value
idEncoder operation =
    case operation of
        Validated id _ ->
            Json.Encode.object
                [ ( "id", Json.Encode.int id ) ]

        _ ->
            Json.Encode.null



{-------------------------
        VERIFIER
--------------------------}


verifyContent : Content -> Result ( Form.Error, List Form.Error ) Content
verifyContent content =
    case ( hasQuotation content, hasInvoice content ) of
        ( True, True ) ->
            verifyWholeContent content

        ( True, False ) ->
            verifyContentWithQuotationOnly content

        ( False, True ) ->
            verifyContentWithInvoiceOnly content

        ( False, False ) ->
            Err ( ( Form.QuotationReference, "entrer un devis ou une facture" ), [] )


hasQuotation : Content -> Bool
hasQuotation content =
    case ( content.quotation.reference, content.quotation.date, content.quotation.amount.value ) of
        ( Nothing, Nothing, Nothing ) ->
            False

        ( _, _, _ ) ->
            True


hasInvoice : Content -> Bool
hasInvoice content =
    case ( content.invoice.reference, content.invoice.date, content.invoice.amount.value ) of
        ( Nothing, Nothing, Nothing ) ->
            False

        ( _, _, _ ) ->
            True


verifyWholeContent : Verify.Validator Form.Error Content Content
verifyWholeContent =
    Verify.validate Content
        |> Verify.verify identity verifyName
        |> Verify.verify identity verifyStore
        |> Verify.verify identity verifyComment
        |> Verify.verify .quotation verifyQuotation
        |> Verify.verify identity verifyInvoiceOrSubvention
        |> Verify.keep .isSubvention


verifyContentWithQuotationOnly : Verify.Validator Form.Error Content Content
verifyContentWithQuotationOnly =
    Verify.validate Content
        |> Verify.verify identity verifyName
        |> Verify.verify identity verifyStore
        |> Verify.verify identity verifyComment
        |> Verify.verify .quotation verifyQuotation
        |> Verify.keep .invoice
        |> Verify.keep .isSubvention


verifyContentWithInvoiceOnly : Verify.Validator Form.Error Content Content
verifyContentWithInvoiceOnly =
    Verify.validate Content
        |> Verify.verify identity verifyName
        |> Verify.verify identity verifyStore
        |> Verify.verify identity verifyComment
        |> Verify.keep .quotation
        |> Verify.verify identity verifyInvoiceOrSubvention
        |> Verify.keep .isSubvention


verifyName : Verify.Validator Form.Error { a | name : String } String
verifyName =
    Verify.validate identity
        |> Verify.verify .name (String.Verify.notBlank ( Form.Name, "merci de donner un nom à cette opération" ))
        |> Verify.compose (verifyString ( Form.Name, "nom invalide" ))


verifyString : error -> Verify.Validator error String String
verifyString error input =
    if Regex.contains stringRegex input then
        Ok input

    else
        Err ( error, [] )


verifyStore : Verify.Validator Form.Error { a | store : String } String
verifyStore =
    Verify.validate identity
        |> Verify.verify .store (verifyString ( Form.Store, "nom de fournisseur invalide" ))


verifyComment : Verify.Validator Form.Error { a | comment : String } String
verifyComment =
    Verify.validate identity
        |> Verify.verify .comment (verifyString ( Form.Comment, "commentaire invalide" ))


verifyQuotation : Verify.Validator Form.Error AccountingEntry AccountingEntry
verifyQuotation =
    Verify.validate AccountingEntry
        |> Verify.verify .reference (verifyMaybeString stringRegex ( Form.QuotationReference, "référence invalide" ))
        |> Verify.verify .date (verifyMaybeString dateRegex ( Form.QuotationDate, "date invalide" ))
        |> Verify.verify .amount (verifyNegativeAmount ( Form.QuotationAmount, "montant invalide" ))


verifyMaybeString : Regex -> Form.Error -> Verify.Validator Form.Error (Maybe String) (Maybe String)
verifyMaybeString regex error input =
    case input of
        Just aString ->
            if Regex.contains regex aString then
                Ok (Just aString)

            else
                Err ( error, [] )

        Nothing ->
            Err ( error, [] )


stringRegex : Regex
stringRegex =
    "^[a-zA-Z0-9!$%&*+?_ ()éèàçù]*$"
        |> Regex.fromStringWith { caseInsensitive = True, multiline = False }
        |> Maybe.withDefault Regex.never


dateRegex : Regex
dateRegex =
    "^[0-9]{2}/[0-9]{2}/[0-9]{4}$"
        |> Regex.fromStringWith { caseInsensitive = True, multiline = False }
        |> Maybe.withDefault Regex.never


verifyNegativeAmount : Form.Error -> Verify.Validator Form.Error { a | value : Maybe Float } { a | value : Maybe Float }
verifyNegativeAmount ( errorField, errorMessage ) input =
    case input.value of
        Just aFloat ->
            if aFloat < 0 then
                Ok input

            else
                Err ( ( errorField, "le montant doit être négatif" ), [] )

        Nothing ->
            Err ( ( errorField, errorMessage ), [] )


verifyInvoiceOrSubvention : Verify.Validator Form.Error { a | invoice : AccountingEntry, isSubvention : Bool } AccountingEntry
verifyInvoiceOrSubvention input =
    case input.isSubvention of
        True ->
            Verify.verify .invoice verifySubvention (Verify.validate identity) input

        _ ->
            Verify.verify .invoice verifyInvoice (Verify.validate identity) input


verifyInvoice : Verify.Validator Form.Error AccountingEntry AccountingEntry
verifyInvoice =
    Verify.validate AccountingEntry
        |> Verify.verify .reference (verifyMaybeString stringRegex ( Form.InvoiceReference, "référence invalide" ))
        |> Verify.verify .date (verifyMaybeString dateRegex ( Form.InvoiceDate, "date invalide" ))
        |> Verify.verify .amount (verifyNegativeAmount ( Form.InvoiceAmount, "montant invalide" ))


verifySubvention : Verify.Validator Form.Error AccountingEntry AccountingEntry
verifySubvention =
    Verify.validate AccountingEntry
        |> Verify.verify .reference (verifyMaybeString stringRegex ( Form.InvoiceReference, "référence invalide" ))
        |> Verify.verify .date (verifyMaybeString dateRegex ( Form.InvoiceDate, "date invalide" ))
        |> Verify.verify .amount (verifyPositiveAmount ( Form.InvoiceAmount, "montant invalide" ))


verifyPositiveAmount : Form.Error -> Verify.Validator Form.Error { a | value : Maybe Float } { a | value : Maybe Float }
verifyPositiveAmount ( errorField, errorMessage ) input =
    case input.value of
        Just aFloat ->
            if aFloat > 0 then
                Ok input

            else
                Err ( ( errorField, "le montant doit être positif" ), [] )

        Nothing ->
            Err ( ( errorField, errorMessage ), [] )

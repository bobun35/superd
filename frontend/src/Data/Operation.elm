module Data.Operation exposing
    ( AccountingEntry
    , AmountField
    , Content
    , Operation(..)
    , asContentIn
    , asNameIn
    , emptyContent
    , getOperationById
    , idEncoder
    , operationDecoder
    , operationEncoder
    )

import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline
import Json.Encode



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



{----------------------------
    INIT AND DEFAULT
-----------------------------}


emptyContent =
    { name = ""
    , store = ""
    , comment = ""
    , quotation = emptyAccountingEntry
    , invoice = emptyAccountingEntry
    }


emptyAccountingEntry =
    { reference = Nothing
    , date = Nothing
    , amount = AmountField Nothing ""
    }



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


asContentIn : Operation -> Content -> Operation
asContentIn operation newContent =
    case operation of
        Validated id content ->
            Validated id newContent

        Create content ->
            Create newContent

        _ ->
            operation


setName : String -> Content -> Content
setName newName content =
    { content | name = newName }


asNameIn : Content -> String -> Content
asNameIn content newName =
    setName newName content



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
        |> Json.Decode.Pipeline.resolve


toDecoder : Int -> String -> String -> String -> Maybe String -> Maybe String -> AmountField -> Maybe String -> Maybe String -> AmountField -> Decoder Operation
toDecoder id name store comment quotationReference quotationDate quotationAmount reference date amount =
    let
        quotation =
            AccountingEntry quotationReference quotationDate quotationAmount

        invoice =
            AccountingEntry reference date amount
    in
    Json.Decode.succeed <| Validated id <| Content name store comment quotation invoice


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

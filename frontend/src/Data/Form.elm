module Data.Form exposing (Error, Field(..))


type Field
    = Comment
    | Email
    | InvoiceAmount
    | InvoiceDate
    | InvoiceReference
    | Name
    | Password
    | QuotationAmount
    | QuotationDate
    | QuotationReference
    | Store


type alias Error =
    ( Field, String )

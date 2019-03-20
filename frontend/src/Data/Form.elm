module Data.Form exposing (Error, Field(..))


type Field
    = Comment
    | Creditor
    | Email
    | InvoiceAmount
    | InvoiceDate
    | InvoiceReference
    | Name
    | Password
    | QuotationAmount
    | QuotationDate
    | QuotationReference
    | Recipient
    | Reference
    | Store
    | Type


type alias Error =
    ( Field, String )

module OperationTests exposing (viewTests)

import Data.Form as Form
import Data.Operation exposing (Operation(..))
import Expect
import Test exposing (Test, describe, test)


validContent =
    { name = "testContent"
    , store = "testStore"
    , comment = "test comment"
    , quotation = testQuotation
    , invoice = testInvoice
    }


testQuotation =
    { reference = Just "test Quotation Reference"
    , date = Just "03/12/2018"
    , amount = { value = Just 5.0, stringValue = "5.0" }
    }


contentWithInvalidQuotationOnly =
    { name = "testContent"
    , store = "testStore"
    , comment = "test comment"
    , quotation = invalidAccountingEntry
    , invoice = unusedAccountingEntry
    }


contentWithInvalidInvoiceOnly =
    { name = ">>>>"
    , store = "testStore"
    , comment = "test comment"
    , quotation = unusedAccountingEntry
    , invoice = invalidAccountingEntry
    }


invalidAccountingEntry =
    { reference = Just "test >>>> Reference"
    , date = Just "03/12/2018"
    , amount = { value = Nothing, stringValue = "5.0" }
    }


unusedAccountingEntry =
    { reference = Nothing
    , date = Nothing
    , amount = { value = Nothing, stringValue = "5.0" }
    }


testInvoice =
    { reference = Just "test Invoice Reference"
    , date = Just "05/12/2018"
    , amount = { value = Just 6.0, stringValue = "6.0" }
    }


viewTests : Test
viewTests =
    describe "operation page elements"
        [ test "operation with valid quotation should pass the verification test" <|
            \() ->
                testQuotation
                    |> Data.Operation.verifyQuotation
                    |> Expect.equal
                        (Ok testQuotation)
        , test "operation with invalid quotation reference should fail verification test" <|
            \() ->
                { testQuotation | reference = Just ">>" }
                    |> Data.Operation.verifyQuotation
                    |> Expect.equal
                        (Err ( ( Form.QuotationReference, "référence invalide" ), [] ))
        , test "operation with invalid quotation reference, date and amount should fail verification test" <|
            \() ->
                { reference = Just ">>"
                , date = Just "3/4/2001"
                , amount = { value = Nothing, stringValue = "0.0" }
                }
                    |> Data.Operation.verifyQuotation
                    |> Expect.equal
                        (Err
                            ( ( Form.QuotationReference, "référence invalide" )
                            , [ ( Form.QuotationDate, "date invalide" )
                              , ( Form.QuotationAmount, "montant invalide" )
                              ]
                            )
                        )
        , test "operation with invalid name should fail verification test" <|
            \() ->
                { validContent | name = ">>" }
                    |> Data.Operation.verifyName
                    |> Expect.equal
                        (Err
                            ( ( Form.Name, "nom invalide" )
                            , []
                            )
                        )
        , test "operation with invalid store should fail verification test" <|
            \() ->
                { validContent | store = ">>" }
                    |> Data.Operation.verifyStore
                    |> Expect.equal
                        (Err
                            ( ( Form.Store, "nom de fournisseur invalide" )
                            , []
                            )
                        )
        , test "content with invalid quotation only should fail verification test" <|
            \() ->
                contentWithInvalidQuotationOnly
                    |> Data.Operation.verifyContent
                    |> Expect.equal
                        (Err
                            ( ( Form.QuotationReference, "référence invalide" )
                            , [ ( Form.QuotationAmount, "montant invalide" ) ]
                            )
                        )
        , test "content with invalid invoice only should fail verification test" <|
            \() ->
                contentWithInvalidInvoiceOnly
                    |> Data.Operation.verifyContent
                    |> Expect.equal
                        (Err
                            ( ( Form.Name, "nom invalide" )
                            , [ ( Form.InvoiceReference, "référence invalide" )
                              , ( Form.InvoiceAmount, "montant invalide" )
                              ]
                            )
                        )
        , test "content with valid quotation and invoice only should pass verification test" <|
            \() ->
                validContent
                    |> Data.Operation.verifyContent
                    |> Expect.equal
                        (Ok validContent)
        ]

import budget.BUDGET_DEFAULT_COMMENT
import budget.BUDGET_DEFAULT_CREDITOR
import budget.BUDGET_DEFAULT_RECIPIENT
import budget.BUDGET_DEFAULT_TYPE
import operation.OperationStatus
import org.joda.time.DateTime

val TEST_EMAIL = "test@superd.net"
val TEST_PASSWORD = "pass123"
val TEST_HASHED_PASSWORD = "1c990ec3487792a0ca16aa7944f7111d287f659a795ca17ec6c00ea4aedd1aff"
val TEST_FIRSTNAME = "firstname"
val TEST_LASTNAME = "lastname"

val TEST_SCHOOL_REFERENCE = "SiretDuPlessis"
val TEST_SCHOOL_NAME = "plessis"
val TEST_SCHOOL2_REFERENCE = "SiretSchool2"
val TEST_SCHOOL2_NAME = "school2"

val TEST_SESSIONID = "sessionId349jklsgio"

val TEST_BUDGET1 = mapOf(
        Pair("name", "NameBudget1"),
        Pair("reference", "ReferenceBudget1"),
        Pair("schoolReference", TEST_SCHOOL_REFERENCE),
        Pair("type", BUDGET_DEFAULT_TYPE),
        Pair("recipient", BUDGET_DEFAULT_RECIPIENT),
        Pair("creditor", BUDGET_DEFAULT_CREDITOR),
        Pair("comment", BUDGET_DEFAULT_COMMENT)
)
val TEST_BUDGET2 = mapOf(
        Pair("name", "NameBudget2"),
        Pair("reference", "ReferenceBudget2"),
        Pair("schoolReference", TEST_SCHOOL2_REFERENCE),
        Pair("type", BUDGET_DEFAULT_TYPE),
        Pair("recipient", BUDGET_DEFAULT_RECIPIENT),
        Pair("creditor", BUDGET_DEFAULT_CREDITOR),
        Pair("comment", BUDGET_DEFAULT_COMMENT)
)


val OPERATION_1 = mapOf(
        Pair("name", "subvention1"),
        Pair("status", OperationStatus.CLOSED),
        Pair("store", "Mairie"),
        Pair("comment", "versement 1"),
        Pair("quotation", null),
        Pair("invoice", null),
        Pair("quotationDate", null),
        Pair("invoiceDate", DateTime(2018, 9, 1, 0, 0, 0)),
        Pair("quotationAmount", null),
        Pair("invoiceAmount", 240309)
)
val OPERATION_2 = mapOf(
        Pair("name", "achat1"),
        Pair("status", OperationStatus.CLOSED),
        Pair("store", "Sadel"),
        Pair("comment", "peinture maternelle"),
        Pair("quotation", "devis01"),
        Pair("invoice", "facture01"),
        Pair("quotationDate", DateTime(2018, 9, 18, 0, 0, 0)),
        Pair("invoiceDate", DateTime(2018, 10, 18, 0, 0, 0)),
        Pair("quotationAmount", -4100),
        Pair("invoiceAmount", -4200)
)
val OPERATION_3 = mapOf(
        Pair("name", "achat2"),
        Pair("status", OperationStatus.ONGOING),
        Pair("store", "Sadel"),
        Pair("comment", "crayons"),
        Pair("quotation", "devis02"),
        Pair("invoice", null),
        Pair("quotationDate", DateTime(2018, 8, 2, 0, 0, 0)),
        Pair("invoiceDate", null),
        Pair("quotationAmount", -7102),
        Pair("invoiceAmount", null)

)
val OPERATION_4 = mapOf(
        Pair("name", "achat3"),
        Pair("amount", -56300),
        Pair("status", OperationStatus.ONGOING),
        Pair("store", "CDiscount"),
        Pair("comment", "enceintes primaire"),
        Pair("quotation", "devis03"),
        Pair("invoice", null),
        Pair("quotationDate", DateTime(2018, 8, 2, 0, 0, 0)),
        Pair("invoiceDate", null),
        Pair("quotationAmount", -56300),
        Pair("invoiceAmount", null)

)
val OPERATION_5 = mapOf(
        Pair("name", "subvention2"),
        Pair("amount", 81300),
        Pair("status", OperationStatus.CLOSED),
        Pair("store", "Association Parents"),
        Pair("comment", "vente des sapins"),
        Pair("quotation", null),
        Pair("invoice", null),
        Pair("quotationDate", null),
        Pair("invoiceDate", DateTime(2018, 10, 10, 0, 0, 0)),
        Pair("quotationAmount", null),
        Pair("invoiceAmount", 81300)
)
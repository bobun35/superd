import budget.BUDGET_DEFAULT_COMMENT
import budget.BUDGET_DEFAULT_CREDITOR
import budget.BUDGET_DEFAULT_RECIPIENT
import budget.BUDGET_DEFAULT_TYPE
import operation.OperationStatus
import operation.OperationType

val TEST_EMAIL = "test@superd.net"
val TEST_PASSWORD = "pass123"
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
        Pair("type", OperationType.CREDIT),
        Pair("amount", 240309),
        Pair("status", OperationStatus.CLOSED),
        Pair("store", "Mairie"),
        Pair("comment", "versement 1")
)
val OPERATION_2 = mapOf(
        Pair("name", "achat1"),
        Pair("type", OperationType.DEBIT),
        Pair("amount", -4200),
        Pair("status", OperationStatus.CLOSED),
        Pair("store", "Sadel"),
        Pair("comment", "peinture maternelle")
)
val OPERATION_3 = mapOf(
        Pair("name", "achat2"),
        Pair("type", OperationType.DEBIT),
        Pair("amount", -7102),
        Pair("status", OperationStatus.ONGOING),
        Pair("store", "Sadel"),
        Pair("comment", "crayons")
)
val OPERATION_4 = mapOf(
        Pair("name", "achat3"),
        Pair("type", OperationType.DEBIT),
        Pair("amount", -56300),
        Pair("status", OperationStatus.ONGOING),
        Pair("store", "CDiscount"),
        Pair("comment", "enceintes primaire")
)
val OPERATION_5 = mapOf(
        Pair("name", "subvention2"),
        Pair("type", OperationType.CREDIT),
        Pair("amount", 81300),
        Pair("status", OperationStatus.ONGOING),
        Pair("store", "Association Parents"),
        Pair("comment", "vente des sapins")
)
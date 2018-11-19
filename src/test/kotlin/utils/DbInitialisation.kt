import budget.*
import com.ninja_squad.dbsetup.destination.DriverManagerDestination
import com.ninja_squad.dbsetup_kotlin.DbSetupBuilder
import com.ninja_squad.dbsetup_kotlin.dbSetup
import common.SqlDb
import io.kotlintest.Description
import io.kotlintest.extensions.TestListener
import operation.*
import org.joda.time.DateTime
import school.SCHOOL_TABLE_NAME
import school.SchoolService
import user.*


object DatabaseListener : TestListener {

    override fun beforeTest(description: Description): Unit {
        prepareDatabase { }
    }
}


fun prepareDatabase(testSpecificConfigurationLambda: DbSetupBuilder.() -> Unit) {
    SqlDb.connect()
    SqlDb.ensureTableExists(UserService.table.users)
    SqlDb.ensureTableExists(SchoolService.table.schools)
    SqlDb.ensureTableExists(BudgetService.table.budgets)

    val destinationDb = DriverManagerDestination(SqlDb.DB_URL, SqlDb.DB_USER, SqlDb.DB_PASSWORD)

    dbSetup(to = destinationDb) {
        deleteAllFrom(USER_TABLE_NAME)
        deleteAllFrom(OPERATION_TABLE_NAME)
        deleteAllFrom(BUDGET_TABLE_NAME)
        deleteAllFrom(SCHOOL_TABLE_NAME)
        testSpecificConfigurationLambda()
    }.launch()
}

fun populateDbWithUsers() {
    populateDbWithSchools()

    val userService = UserService()
    userService.createUserInDb(TEST_EMAIL, TEST_PASSWORD, TEST_FIRSTNAME, TEST_LASTNAME, TEST_SCHOOL_REFERENCE)
}

fun populateDbWithSchools() {
    val schoolService = SchoolService()
    schoolService.createSchoolInDb(TEST_SCHOOL_REFERENCE, TEST_SCHOOL_NAME)
    schoolService.createSchoolInDb(TEST_SCHOOL2_REFERENCE, TEST_SCHOOL2_NAME)
}

fun populateDbWithBudgets() {
    populateDbWithSchools()
    val budgetService = BudgetService()
    createBudgetInDbFromMap(budgetService, TEST_BUDGET1)
    createBudgetInDbFromMap(budgetService, TEST_BUDGET2)
}

private fun createBudgetInDbFromMap(budgetService: BudgetService, budgetMap: Map<String, String>) {
    budgetService.createBudgetInDb(
            budgetMap.get("name")!!,
            budgetMap.get("reference")!!,
            budgetMap.get("schoolReference")!!,
            budgetMap.get("type")!!,
            budgetMap.get("recipient")!!,
            budgetMap.get("creditor")!!,
            budgetMap.get("comment")!!)
}

fun populateDbWithOperations() {
    populateDbWithBudgets()
    val budgetModel = BudgetModel()
    val operationService = OperationService()

    val budgetId = budgetModel.getFirstBudgetIdBySchoolReference(TEST_SCHOOL_REFERENCE)
    createOperationInDbFromMap(operationService, budgetId, OPERATION_1)
    createOperationInDbFromMap(operationService, budgetId, OPERATION_2)
    createOperationInDbFromMap(operationService, budgetId, OPERATION_3)
    createOperationInDbFromMap(operationService, budgetId, OPERATION_4)
    createOperationInDbFromMap(operationService, budgetId, OPERATION_5)

    val budgetId2 = budgetModel.getFirstBudgetIdBySchoolReference(TEST_SCHOOL2_REFERENCE)
    createOperationInDbFromMap(operationService, budgetId2, OPERATION_2)
    createOperationInDbFromMap(operationService, budgetId2, OPERATION_3)
    createOperationInDbFromMap(operationService, budgetId2, OPERATION_4)
}

private fun createOperationInDbFromMap(operationService: OperationService, budgetId: Int,
                                       operationMap: Map<String, Any?>) {
    operationService.createOperationInDb(
            operationMap.get("name")!! as String,
            operationMap.get("status")!! as OperationStatus,
            budgetId,
            operationMap.get("store")!! as String,
            operationMap.get("comment") as String?,
            operationMap.get("quotation") as String?,
            operationMap.get("invoice") as String?,
            operationMap.get("quotationDate") as DateTime?,
            operationMap.get("invoiceDate") as DateTime?,
            operationMap.get("quotationAmount") as Int?,
            operationMap.get("invoiceAmount") as Int?
    )
}
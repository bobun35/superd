import budget.*
import com.ninja_squad.dbsetup.destination.DriverManagerDestination
import com.ninja_squad.dbsetup_kotlin.DbSetupBuilder
import com.ninja_squad.dbsetup_kotlin.dbSetup
import common.SqlDb
import io.kotlintest.Description
import io.kotlintest.extensions.TestListener
import operation.OperationService
import operation.OperationStatus
import operation.OperationType
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

    dbSetup(to=destinationDb) {
        deleteAllFrom(USER_TABLE_NAME)
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
}

fun populateDbWithBudgets() {
    populateDbWithSchools()
    val budgetService = BudgetService()
    budgetService.createBudgetInDb("testBudgetName", "testBudgetReference",
            TEST_SCHOOL_REFERENCE, BUDGET_DEFAULT_TYPE,
            BUDGET_DEFAULT_RECIPIENT, BUDGET_DEFAULT_CREDITOR,
            BUDGET_DEFAULT_COMMENT)
}
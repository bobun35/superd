import com.ninja_squad.dbsetup.destination.DriverManagerDestination
import com.ninja_squad.dbsetup_kotlin.DbSetupBuilder
import com.ninja_squad.dbsetup_kotlin.dbSetup
import common.SqlDb
import io.kotlintest.Description
import io.kotlintest.extensions.TestListener
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

    val destinationDb = DriverManagerDestination(SqlDb.DB_URL, SqlDb.DB_USER, SqlDb.DB_PASSWORD)

    dbSetup(to=destinationDb) {
        deleteAllFrom(USER_TABLE_NAME)
        deleteAllFrom(SCHOOL_TABLE_NAME)
        testSpecificConfigurationLambda()
    }.launch()
}

fun populateDbWithUsers() {
    populateDbWithSchools()

    val userService = UserService()
    userService.createUserInDb(TEST_EMAIL, TEST_PASSWORD, TEST_SCHOOL)
}

fun populateDbWithSchools() {
    val schoolService = SchoolService()
    schoolService.createSchoolInDb(TEST_SCHOOL)
}
import com.ninja_squad.dbsetup.destination.DriverManagerDestination
import com.ninja_squad.dbsetup_kotlin.DbSetupBuilder
import com.ninja_squad.dbsetup_kotlin.dbSetup
import common.SqlDb
import user.UserService
import user.USER_TABLE_NAME


fun prepareDatabase(testSpecificConfigurationLambda: DbSetupBuilder.() -> Unit) {
    SqlDb.connect()
    SqlDb.ensureTableExists(UserService.table.users)

    val destinationDb = DriverManagerDestination(SqlDb.DB_URL, SqlDb.DB_USER, SqlDb.DB_PASSWORD)

    dbSetup(to=destinationDb) {
        deleteAllFrom(USER_TABLE_NAME)
        testSpecificConfigurationLambda()
    }.launch()
}
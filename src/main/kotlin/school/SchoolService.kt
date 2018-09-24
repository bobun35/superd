package school

import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction


const val SCHOOL_TABLE_NAME = "schools"

data class School(val id: Int, val siret: String)

class SchoolService {

    object table {
        // object name and database table name shall be the same
        object schools : Table() {
            val id = integer("id").autoIncrement().primaryKey()
            val siret = varchar("siret", 100).uniqueIndex()
        }
    }

    companion object: KLoggable {
        override val logger = logger()
    }

    init {
        SqlDb.connect()
        SqlDb.ensureTableExists(table.schools)
    }

    fun populateSchools() {
        SqlDb.flush(table.schools)
        createSchoolInDb("plessis")
    }

    fun createSchoolInDb(siret: String) {
        try {
            transaction {
                table.schools.insert {
                    it[table.schools.siret] = siret
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
    }

    fun getSchoolBySiret(siret: String): School? {
        return getSchool { table.schools.siret eq siret }
    }

    fun getSchoolById(id: Int): School? {
        return getSchool { table.schools.id eq id }
    }

    private fun getSchool(where: SqlExpressionBuilder.()-> Op<Boolean>): School? {
        var school: School? = null
        try {
            transaction {
                val result = table.schools.select( where )
                if (result.count() == 1) {
                    for (row in result) {
                        school = School(
                                row[table.schools.id],
                                row[table.schools.siret])
                    }
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
        return school
    }
}

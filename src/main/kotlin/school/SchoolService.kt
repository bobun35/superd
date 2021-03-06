package school

import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction


const val SCHOOL_TABLE_NAME = "schools"

data class School(val id: Int, val reference: String, val name: String)

class SchoolService {

    object table {
        // object name and database table name shall be the same
        object schools : Table() {
            val id = integer("id").autoIncrement().primaryKey()
            val reference = varchar("reference", 100).uniqueIndex()
            val name = varchar("name", 100)
        }
    }

    companion object: KLoggable {
        override val logger = logger()
    }

    init {
        SqlDb.connect()
        SqlDb.ensureTableExists(table.schools)
    }

    fun flush() {
        SqlDb.flush(table.schools)
    }

    fun populate() {
        createInDb("SiretDuPlessis", "Plessis")
    }

    fun createInDb(reference: String, name: String) {
        try {
            transaction {
                table.schools.insert {
                    it[table.schools.reference] = reference
                    it[table.schools.name] = name
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
    }

    fun getByReference(reference: String): School? {
        return get { table.schools.reference eq reference }
    }

    fun getById(id: Int): School? {
        return get { table.schools.id eq id }
    }

    private fun get(where: SqlExpressionBuilder.()-> Op<Boolean>): School? {
        var school: School? = null
        try {
            transaction {
                val result = table.schools.select( where )
                if (result.count() == 1) {
                    for (row in result) {
                        school = School(
                                row[table.schools.id],
                                row[table.schools.reference],
                                row[table.schools.name])
                    }
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
        return school
    }
}

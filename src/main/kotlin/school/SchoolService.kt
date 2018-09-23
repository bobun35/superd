package school

import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.select
import org.jetbrains.exposed.sql.transactions.transaction


const val SCHOOL_TABLE_NAME = "schools"

data class School(val schoolId: Int, val schoolName: String)

class SchoolService {

    object table {
        // object name and database table name shall be the same
        object schools : Table() {
            val schoolId = integer("id").autoIncrement().primaryKey()
            val schoolName = varchar("school_name", 100).uniqueIndex()
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

    fun createSchoolInDb(name: String) {
        try {
            transaction {
                table.schools.insert {
                    it[table.schools.schoolName] = name
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
    }

    fun getSchool(name: String): School? {
        var school: School? = null
        try {
            transaction {
                val result = table.schools.select( { table.schools.schoolName eq name } )
                if (result.count() == 1) {
                    for (row in result) {
                        school = School(
                                row[table.schools.schoolId],
                                row[table.schools.schoolName])
                    }
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
        return school
    }
}

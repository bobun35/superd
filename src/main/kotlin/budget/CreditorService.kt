package budget

import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import school.School
import school.SchoolService

class CreditorService {

    object table {
        // object name and database table name shall be the same
        object creditors : Table() {
            val id = integer("id").autoIncrement().primaryKey()
            val name = varchar("name", 100)
            val schoolId = integer("school_id") references SchoolService.table.schools.id
        }
    }

    companion object : KLoggable {
        override val logger = logger()
    }

    init {
        SqlDb.connect()
        SqlDb.ensureTableExists(table.creditors)
    }

    fun flush() {
        SqlDb.flush(table.creditors)
    }

    fun populate() {
        SqlDb.flush(table.creditors)
        val schoolService = SchoolService()
        val school: School = schoolService.getByReference("SiretDuPlessis")!!
        createInDb("mairie", school.id)
        createInDb("ape", school.id)
    }

    fun createInDb(name: String,
                   schoolId: Int): Int? {
        try {

            val creditorId = transaction {
                table.creditors.insert {
                    it[table.creditors.name] = name
                    it[table.creditors.schoolId] = schoolId
                }
            }
            return creditorId.generatedKey?.toInt()
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
            return null
        }
    }

    fun getBySchoolId(schoolId: Int): List<GenericBudgetItem> {
        return get { table.creditors.schoolId eq schoolId }
    }

    fun getBySchoolIdAndName(schoolId: Int, name: String): GenericBudgetItem {
        val nameEq = CreditorService.table.creditors.name eq name
        val shoolIdEq = CreditorService.table.creditors.schoolId eq schoolId
        return get { shoolIdEq and nameEq }.first()
    }

    fun getName(id: Int): String {
        return get { table.creditors.id eq id }.first().name
    }

    private fun get(where: SqlExpressionBuilder.()-> Op<Boolean>): List<GenericBudgetItem> {
        var creditors = mutableListOf<GenericBudgetItem>()
        try {
            transaction {
                val result = CreditorService.table.creditors.select( where )
                for (row in result) {
                    creditors.add( GenericBudgetItem(
                            row[CreditorService.table.creditors.id],
                            row[CreditorService.table.creditors.name],
                            row[CreditorService.table.creditors.schoolId]
                    )
                    )
                }
            }
        } catch (exception: Exception) {
            CreditorService.logger.error("Database error: " + exception.message)
        }
        return creditors
    }

}
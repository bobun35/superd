package budget

import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import school.School
import school.SchoolService

class RecipientService {

    object table {
        // object name and database table name shall be the same
        object recipients : Table() {
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
        SqlDb.ensureTableExists(table.recipients)
    }

    fun flush() {
        SqlDb.flush(table.recipients)
    }

    fun populate() {
        SqlDb.flush(table.recipients)
        val schoolService = SchoolService()
        val school: School = schoolService.getByReference("SiretDuPlessis")!!
        createInDb("maternelle", school.id)
        createInDb("élémentaire", school.id)
        createInDb("général", school.id)
    }

    fun createInDb(name: String,
                   schoolId: Int): Int? {
        try {

            val recipientId = transaction {
                table.recipients.insert {
                    it[table.recipients.name] = name
                    it[table.recipients.schoolId] = schoolId
                }
            }
            return recipientId.generatedKey?.toInt()
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
            return null
        }
    }

    fun getBySchoolId(schoolId: Int): List<GenericBudgetItem> {
        return get { table.recipients.schoolId eq schoolId }
    }

    fun getBySchoolIdAndName(schoolId: Int, name: String): GenericBudgetItem {
        val nameEq = RecipientService.table.recipients.name eq name
        val shoolIdEq = RecipientService.table.recipients.schoolId eq schoolId
        return get { shoolIdEq and nameEq }.first()
    }

    fun getName(id: Int): String {
        return get { table.recipients.id eq id }.first().name
    }

    private fun get(where: SqlExpressionBuilder.()-> Op<Boolean>): List<GenericBudgetItem> {
        var recipients = mutableListOf<GenericBudgetItem>()
        try {
            transaction {
                val result = RecipientService.table.recipients.select( where )
                for (row in result) {
                    recipients.add( GenericBudgetItem(
                            row[RecipientService.table.recipients.id],
                            row[RecipientService.table.recipients.name],
                            row[RecipientService.table.recipients.schoolId]
                    )
                    )
                }
            }
        } catch (exception: Exception) {
            RecipientService.logger.error("Database error: " + exception.message)
        }
        return recipients
    }

}
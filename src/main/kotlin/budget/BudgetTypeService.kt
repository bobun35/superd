package budget

import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import school.School
import school.SchoolService

data class GenericBudgetItem(val id: Int,
                             val name: String,
                             val schoolId: Int
)

class BudgetTypeService {

    object table {
        // object name and database table name shall be the same
        object budget_types : Table() {
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
        SqlDb.ensureTableExists(table.budget_types)
    }

    fun flush() {
        SqlDb.flush(table.budget_types)
    }

    fun populate() {
        SqlDb.flush(table.budget_types)
        val schoolService = SchoolService()
        val school: School = schoolService.getByReference("SiretDuPlessis")!!
        createInDb("fonctionnement", school.id)
        createInDb("ape", school.id)
    }

    fun createInDb(name: String,
                   schoolId: Int): Int? {
        try {

            val budgetTypeId = transaction {
                table.budget_types.insert {
                    it[table.budget_types.name] = name
                    it[table.budget_types.schoolId] = schoolId
                }
            }
            return budgetTypeId.generatedKey?.toInt()
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
            return null
        }
    }

    fun getBySchoolId(schoolId: Int): List<GenericBudgetItem> {
        return get { table.budget_types.schoolId eq schoolId }
    }

    fun getBySchoolIdAndName(schoolId: Int, name: String): GenericBudgetItem {
        val nameEq = BudgetTypeService.table.budget_types.name eq name
        val shoolIdEq = BudgetTypeService.table.budget_types.schoolId eq schoolId
        return get { shoolIdEq and nameEq }.first()
    }

    fun getName(id: Int): String {
        return get { table.budget_types.id eq id }.first().name
    }

    private fun get(where: SqlExpressionBuilder.()-> Op<Boolean>): List<GenericBudgetItem> {
        var budgetTypes = mutableListOf<GenericBudgetItem>()
        try {
            transaction {
                val result = BudgetTypeService.table.budget_types.select( where )
                for (row in result) {
                    budgetTypes.add( GenericBudgetItem(
                            row[BudgetTypeService.table.budget_types.id],
                            row[BudgetTypeService.table.budget_types.name],
                            row[BudgetTypeService.table.budget_types.schoolId]
                        )
                    )
                }
            }
        } catch (exception: Exception) {
            BudgetTypeService.logger.error("Database error: " + exception.message)
        }
        return budgetTypes
    }

}
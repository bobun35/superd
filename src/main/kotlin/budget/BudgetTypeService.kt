package budget

import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.SqlExpressionBuilder.eq
import org.jetbrains.exposed.sql.transactions.transaction
import school.School
import school.SchoolService

data class BudgetType(val id: Int,
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

    fun flushBudgetTypes() {
        SqlDb.flush(table.budget_types)
    }

    fun populateBudgetTypes() {
        SqlDb.flush(table.budget_types)
        val schoolService = SchoolService()
        val school: School = schoolService.getSchoolByReference("SiretDuPlessis")!!
        createBudgetTypeInDb("fonctionnement", school.id)
    }

    fun createBudgetTypeInDb(name: String,
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

    fun getBySchoolId(schoolId: Int): List<BudgetType> {
        return getBudgetTypes { BudgetTypeService.table.budget_types.schoolId eq schoolId }
    }

    fun getBySchoolIdAndName(schoolId: Int, name: String): BudgetType {
        val nameEq = BudgetTypeService.table.budget_types.name eq name
        val shoolIdEq = BudgetTypeService.table.budget_types.schoolId eq schoolId
        return getBudgetTypes { shoolIdEq and nameEq }.first()
    }

    fun getName(id: Int): String {
        return getBudgetTypes { BudgetTypeService.table.budget_types.id eq id }.first().name
    }

    private fun getBudgetTypes(where: SqlExpressionBuilder.()-> Op<Boolean>): List<BudgetType> {
        var budgetTypes = mutableListOf<BudgetType>()
        try {
            transaction {
                val result = BudgetTypeService.table.budget_types.select( where )
                for (row in result) {
                    budgetTypes.add( BudgetType(
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
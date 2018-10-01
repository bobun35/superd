package budget

import com.fasterxml.jackson.annotation.JsonIgnore
import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import school.School
import school.SchoolService


const val BUDGET_TABLE_NAME = "budgets"

enum class Status { OPEN, CLOSED, TRASHED}

data class Budget(val id: Int,
                  val name: String,
                  val reference: String,
                  @JsonIgnore
                  val status: Status,
                  @JsonIgnore
                  val schoolId: Int,
                  val realRemaining: Float = 0f,
                  val virtualRemaining: Float = 0f)

class BudgetService {

    object table {
        // object name and database table name shall be the same
        object budgets : Table() {
            val id = integer("id").autoIncrement().primaryKey()
            val name = varchar("name", 100)
            val reference = varchar("reference", 100)
            val status = enumeration("status", Status::class.java)
            val schoolId = integer("school_id") references SchoolService.table.schools.id

            // TODO replace by foreign key to budget_types table
            //val type = varchar("type", 100)

            // TODO replace by foreign key to budget_categories table
            //val category = varchar("category", 100)

            // TODO replace by foreign key to budget_creditors table
            //val creditor = varchar("creditor", 100)

            // TODO add creation date
            //val creationDate = datetime("creation_date")

            }
    }

    companion object: KLoggable {
        override val logger = logger()
    }

    init {
        SqlDb.connect()
        SqlDb.ensureTableExists(table.budgets)
    }

    fun flushBudgets() {
        SqlDb.flush(table.budgets)
    }

    fun populateBudgets() {
        SqlDb.flush(table.budgets)
        createBudgetInDb("budget01", "REF0001", "SiretDuPlessis")
        createBudgetInDb("budget02", "REF0002", "SiretDuPlessis")
        createBudgetInDb("budget02", "REF0003", "SiretDuPlessis")
    }

    fun createBudgetInDb(name: String, reference: String, schoolReference: String) {
        try {
            // get id from Name
            val schoolService = SchoolService()
            val school: School? = schoolService.getSchoolByReference(schoolReference)

            transaction {
                table.budgets.insert {
                    it[table.budgets.name] = name
                    it[table.budgets.reference] = reference
                    it[table.budgets.status] = Status.OPEN
                    it[table.budgets.schoolId] = school!!.id
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
    }

    fun getBudgetsBySchoolId(schoolId: Int): List<Budget> {
        return getBudgets { (table.budgets.schoolId eq schoolId) and (table.budgets.status eq Status.OPEN) }
    }

    private fun getBudgets(where: SqlExpressionBuilder.()-> Op<Boolean>): List<Budget> {
        var budgets = mutableListOf<Budget>()
        try {
            transaction {
                val result = table.budgets.select( where )
                for (row in result) {
                        budgets.add( Budget(
                                        row[table.budgets.id],
                                        row[table.budgets.name],
                                        row[table.budgets.reference],
                                        row[table.budgets.status],
                                        row[table.budgets.schoolId]
                                )
                        )
                    }
                }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
        return budgets
    }
}

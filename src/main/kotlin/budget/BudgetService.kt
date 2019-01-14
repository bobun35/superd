package budget

import common.SqlDb
import mu.KLoggable
import operation.Operation
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import school.School
import school.SchoolService


const val BUDGET_TABLE_NAME = "budgets"
const val BUDGET_DEFAULT_TYPE = "fonctionnement"
const val BUDGET_DEFAULT_RECIPIENT = "général"
const val BUDGET_DEFAULT_CREDITOR = "mairie"
const val BUDGET_DEFAULT_COMMENT = "budget de test"

enum class Status { OPEN, CLOSED, TRASHED }

/*
    reference: reference comptable
    status: open / closed / trashed
    recipient: e.g. maternelle primaire général
    creditor: e.g. mairie coop
    comment: commentaire sur le budget
    realRemaining: reste réel (commandes en cours non prise en compte)
    virtualRemaining: reste virtuel (commandes en cours déduites)

 */
interface IBudget {
    val id: Int
    val name: String
    val reference: String
    val schoolId: Int
    val recipient: String
    val creditor: String
    val comment: String
    var realRemaining: Double
    var virtualRemaining: Double
    var operations: List<Operation>
}

data class Budget(override val id: Int,
                  override val name: String,
                  override val reference: String,
                  val status: Status,
                  override val schoolId: Int,
                  val type: Int,
                  override val recipient: String,
                  override val creditor: String,
                  override val comment: String,
                  override var realRemaining: Double = 0.0,
                  override var virtualRemaining: Double = 0.0,
                  override var operations: List<Operation> = listOf()
) : IBudget

data class BudgetForIHM(override val id: Int,
                        override val name: String,
                        override val reference: String,
                        override val schoolId: Int,
                        val type: String,
                        override val recipient: String,
                        override val creditor: String,
                        override val comment: String,
                        override var realRemaining: Double = 0.0,
                        override var virtualRemaining: Double = 0.0,
                        override var operations: List<Operation> = listOf()
) : IBudget

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
            val type = integer("type") references BudgetTypeService.table.budget_types.id

            // TODO replace by foreign key to budget_recipients table
            val recipient = varchar("recipient", 100)

            // TODO replace by foreign key to budget_creditors table
            val creditor = varchar("creditor", 100)

            val comment = varchar("comment", 255)
            //val creationDate = date("creation_date")
        }
    }

    companion object : KLoggable {
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

        val schoolService = SchoolService()
        val school: School = schoolService.getSchoolByReference("SiretDuPlessis")!!

        val budgetTypeService = BudgetTypeService()
        val budgetType: BudgetType = budgetTypeService.getBySchoolId(school.id)!!.first()

        createBudgetInDb("budget01", "REF0001", school.id, budgetType.id)
        createBudgetInDb("budget02", "REF0002", school.id, budgetType.id)
        createBudgetInDb("budget02", "REF0003", school.id, budgetType.id)
    }

    fun createBudgetInDb(name: String,
                         reference: String,
                         schoolId: Int,
                         type: Int,
                         recipient: String? = null,
                         creditor: String? = null,
                         comment: String? = null): Int? {
        try {

            val budgetId = transaction {
                table.budgets.insert {
                    it[table.budgets.name] = name
                    it[table.budgets.reference] = reference
                    it[table.budgets.status] = Status.OPEN
                    it[table.budgets.schoolId] = schoolId
                    it[table.budgets.type] = type
                    it[table.budgets.recipient] = recipient ?: BUDGET_DEFAULT_RECIPIENT
                    it[table.budgets.creditor] = creditor ?: BUDGET_DEFAULT_CREDITOR
                    it[table.budgets.comment] = comment ?: BUDGET_DEFAULT_COMMENT
                }
            }
            return budgetId.generatedKey?.toInt()
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
            return null
        }
    }

    fun getBudgetsBySchoolId(schoolId: Int): List<Budget> {
        return getBudgets { (table.budgets.schoolId eq schoolId) and (table.budgets.status eq Status.OPEN) }
    }

    fun getBudgetIdsBySchoolId(schoolId: Int): List<Int> {
        val budgets = getBudgets { (table.budgets.schoolId eq schoolId) and (table.budgets.status eq Status.OPEN) }
        return budgets.map { it.id }
    }

    fun getBudgetById(id: Int): Budget {
        return getBudgets { table.budgets.id eq id }.first()
    }

    fun getBudgetBySchoolReference(schoolReference: String): List<Budget> {
        val schoolService = SchoolService()
        val school: School? = schoolService.getSchoolByReference(schoolReference)
        return getBudgetsBySchoolId(school!!.id)
    }

    private fun getBudgets(where: SqlExpressionBuilder.() -> Op<Boolean>): List<Budget> {
        var budgets = mutableListOf<Budget>()
        try {
            transaction {
                val result = table.budgets.select(where)
                for (row in result) {
                    budgets.add(Budget(
                            row[table.budgets.id],
                            row[table.budgets.name],
                            row[table.budgets.reference],
                            row[table.budgets.status],
                            row[table.budgets.schoolId],
                            row[table.budgets.type],
                            row[table.budgets.recipient],
                            row[table.budgets.creditor],
                            row[table.budgets.comment]
                    )
                    )
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
        return budgets
    }

    fun modifyAllFields(id: Int,
                        name: String,
                        reference: String,
                        type: Int,
                        recipient: String,
                        creditor: String,
                        comment: String) {
        if (id == null) {
            throw IllegalArgumentException("budget id is null, budget cannot be modified")
        }
        try {
            transaction {
                table.budgets.update({ table.budgets.id eq id }) {
                    it[table.budgets.name] = name
                    it[table.budgets.reference] = reference
                    it[table.budgets.comment] = comment ?: ""
                    it[table.budgets.type] = type
                    it[table.budgets.recipient] = recipient
                    it[table.budgets.creditor] = creditor
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
            throw exception
        }
    }

}

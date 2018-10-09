package budget

import com.fasterxml.jackson.annotation.JsonIgnore
import common.SqlDb
import mu.KLoggable
import operation.Operation
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import org.joda.time.DateTime
import school.School
import school.SchoolService


const val BUDGET_TABLE_NAME = "budgets"
const val BUDGET_DEFAULT_TYPE = "fonctionnement"
const val BUDGET_DEFAULT_RECIPIENT = "général"
const val BUDGET_DEFAULT_CREDITOR = "mairie"
const val BUDGET_DEFAULT_COMMENT = "budget de test"

enum class Status { OPEN, CLOSED, TRASHED}

data class Budget(val id: Int,
                  val name: String,
                  val reference: String, // reference comptable
                  val status: Status,
                  @JsonIgnore
                  val schoolId: Int,
                  val type: String, // e.g. fonctionnement, investissement
                  val recipient: String, // e.g. maternelle, primaire, général
                  val creditor: String, // e.g. mairie, coop
                  val comment: String, // commentaire sur le budget
                  //val creationDate: DateTime,
                  var realRemaining: Double = 0.0, // reste réel (commandes en cours non prise en compte)
                  var virtualRemaining: Double = 0.0, // reste virtuel (commandes en cours déduites)
                  var operations: List<Operation> = listOf()
)

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
            val type = varchar("type", 100)

            // TODO replace by foreign key to budget_recipients table
            val recipient = varchar("recipient", 100)

            // TODO replace by foreign key to budget_creditors table
            val creditor = varchar("creditor", 100)

            val comment = varchar("comment", 255)
            //val creationDate = date("creation_date")
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

    fun createBudgetInDb(name: String,
                         reference: String,
                         schoolReference: String,
                         type: String? = null,
                         recipient: String? = null,
                         creditor: String? = null,
                         comment: String? = null) {
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
                    it[table.budgets.type] = type ?: BUDGET_DEFAULT_TYPE
                    it[table.budgets.recipient] = recipient ?: BUDGET_DEFAULT_RECIPIENT
                    it[table.budgets.creditor] = creditor ?: BUDGET_DEFAULT_CREDITOR
                    it[table.budgets.comment] = comment ?: BUDGET_DEFAULT_COMMENT
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
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

}

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
                  val typeId: Int,
                  val recipientId: Int,
                  val creditorId: Int,
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
                        val recipient: String,
                        val creditor: String,
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
            val typeId = integer("type_id") references BudgetTypeService.table.budget_types.id
            val recipientId = integer("recipient_id") references RecipientService.table.recipients.id
            val creditorId = integer("creditor_id") references CreditorService.table.creditors.id
            val comment = varchar("comment", 255)
        }
    }

    companion object : KLoggable {
        override val logger = logger()
    }

    init {
        SqlDb.connect()
        SqlDb.ensureTableExists(table.budgets)
    }

    fun flush() {
        SqlDb.flush(table.budgets)
    }

    fun populate() {
        SqlDb.flush(table.budgets)

        val schoolService = SchoolService()
        val school: School = schoolService.getByReference("SiretDuPlessis")!!

        val budgetTypeService = BudgetTypeService()
        val budgetType: GenericBudgetItem = budgetTypeService.getBySchoolId(school.id)!!.first()

        val recipientService = RecipientService()
        val recipient: GenericBudgetItem = recipientService.getBySchoolId(school.id)!!.first()

        val creditorService = CreditorService()
        val creditor: GenericBudgetItem = creditorService.getBySchoolId(school.id)!!.first()

        createInDb("budget01", "REF0001", school.id, budgetType.id, recipient.id, creditor.id)
        createInDb("budget02", "REF0002", school.id, budgetType.id, recipient.id, creditor.id)
        createInDb("budget02", "REF0003", school.id, budgetType.id, recipient.id, creditor.id)
    }

    fun createInDb(name: String,
                   reference: String,
                   schoolId: Int,
                   typeId: Int,
                   recipientId: Int,
                   creditorId: Int,
                   comment: String? = null): Int? {
        try {

            val budgetId = transaction {
                table.budgets.insert {
                    it[table.budgets.name] = name
                    it[table.budgets.reference] = reference
                    it[table.budgets.status] = Status.OPEN
                    it[table.budgets.schoolId] = schoolId
                    it[table.budgets.typeId] = typeId
                    it[table.budgets.recipientId] = recipientId
                    it[table.budgets.creditorId] = creditorId
                    it[table.budgets.comment] = comment ?: BUDGET_DEFAULT_COMMENT
                }
            }
            return budgetId.generatedKey?.toInt()
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
            return null
        }
    }

    fun getBySchoolId(schoolId: Int): List<Budget> {
        return get { (table.budgets.schoolId eq schoolId) and (table.budgets.status eq Status.OPEN) }
    }

    fun getBudgetIdsBySchoolId(schoolId: Int): List<Int> {
        val budgets = get { (table.budgets.schoolId eq schoolId) and (table.budgets.status eq Status.OPEN) }
        return budgets.map { it.id }
    }

    fun getById(id: Int): Budget {
        return get { table.budgets.id eq id }.first()
    }

    fun getBySchoolReference(schoolReference: String): List<Budget> {
        val schoolService = SchoolService()
        val school: School? = schoolService.getByReference(schoolReference)
        return getBySchoolId(school!!.id)
    }

    private fun get(where: SqlExpressionBuilder.() -> Op<Boolean>): List<Budget> {
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
                            row[table.budgets.typeId],
                            row[table.budgets.recipientId],
                            row[table.budgets.creditorId],
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
                        typeId: Int,
                        recipientId: Int,
                        creditorId: Int,
                        comment: String) {
        if (id == null) {
            throw IllegalArgumentException("budget id is null, budget cannot be modified")
        }
        try {
            transaction {
                table.budgets.update({ table.budgets.id eq id }) {
                    it[table.budgets.name] = name
                    it[table.budgets.reference] = reference
                    it[table.budgets.typeId] = typeId
                    it[table.budgets.recipientId] = recipientId
                    it[table.budgets.creditorId] = creditorId
                    it[table.budgets.comment] = comment ?: ""
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
            throw exception
        }
    }

}

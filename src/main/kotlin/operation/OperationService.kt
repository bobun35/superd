package operation

import budget.BudgetService
import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import kotlin.math.round

const val OPERATION_TABLE_NAME = "operations"

enum class OperationStatus { ONGOING, CLOSED }

enum class OperationType { DEBIT, CREDIT }

data class Operation(val id: Int,
                     val name: String,
                     val type: OperationType,
                     val amount: Int,
                     val status: OperationStatus,
                     val budgetId: Int,
                     val store: String,
                     val comment: String, // commentaire sur l'opération
                     val quotation: String, // devis
                     val invoice: String // facture
        //val creationDate: DateTime
)

fun List<Operation>.sumAmounts(): Int {
    return this.sumBy { it.amount }
}

class OperationService {

    object table {
        // object name and database table name shall be the same
        object operations : Table() {
            val id = integer("id").autoIncrement().primaryKey()
            val name = varchar("name", 100)
            val type = enumeration("type", OperationType::class.java)
            val amount = integer("amount") // en centimes
            val status = enumeration("status", OperationStatus::class.java)
            val budgetId = integer("budget_id") references BudgetService.table.budgets.id
            val store = varchar("store", 100)
            val comment = varchar("comment", 255)
            val quotation = varchar("quotation", 25) // reference devis
            val invoice = varchar("invoice", 255) // reference facture
            //val creationDate = date("creation_date")
        }
    }

    companion object : KLoggable {
        override val logger = logger()
    }

    init {
        SqlDb.connect()
        SqlDb.ensureTableExists(table.operations)
    }

    fun flushOperations() {
        SqlDb.flush(table.operations)
    }

    fun populateOperations(budgetId: Int) {
        SqlDb.flush(table.operations)
        createOperationInDb("subvention 1", OperationType.CREDIT, 230409,
                OperationStatus.CLOSED, budgetId, "Mairie", "1er versement")
        createOperationInDb("dépense 1", OperationType.DEBIT, -5000,
                OperationStatus.ONGOING, budgetId, "Sadel", "stylos",
                "devis001", "facture001")
        createOperationInDb("dépense 2", OperationType.DEBIT, -40600,
                OperationStatus.ONGOING, budgetId, "Sadel", "peinture",
                "devis002", "facture002")
    }

    fun createOperationInDb(name: String,
                            type: OperationType,
                            amount: Int,
                            status: OperationStatus,
                            budgetId: Int,
                            store: String,
                            comment: String? = null,
                            quotation: String? = null,
                            invoice: String? = null) {
        try {
            transaction {
                table.operations.insert {
                    it[table.operations.name] = name
                    it[table.operations.type] = type
                    it[table.operations.amount] = amount
                    it[table.operations.status] = status
                    it[table.operations.budgetId] = budgetId
                    it[table.operations.store] = store
                    it[table.operations.comment] = comment ?: ""
                    it[table.operations.quotation] = quotation ?: ""
                    it[table.operations.invoice] = invoice ?: ""
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
    }

    fun getAllOperationsByBudgetId(id: Int): List<Operation> {
        return getOperations { (table.operations.budgetId eq id) }
    }

    fun getAlreadyPaidOperationsByBudgetId(id: Int): List<Operation> {
        return getOperations { (table.operations.budgetId eq id) and (table.operations.status eq OperationStatus.CLOSED) }
    }

    private fun getOperations(where: SqlExpressionBuilder.() -> Op<Boolean>): List<Operation> {
        var operations = mutableListOf<Operation>()
        try {
            transaction {
                val result = table.operations.select(where)
                for (row in result) {
                    operations.add(Operation(
                            row[table.operations.id],
                            row[table.operations.name],
                            row[table.operations.type],
                            row[table.operations.amount],
                            row[table.operations.status],
                            row[table.operations.budgetId],
                            row[table.operations.store],
                            row[table.operations.comment],
                            row[table.operations.quotation],
                            row[table.operations.invoice]
                    )
                    )
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
        return operations
    }
}

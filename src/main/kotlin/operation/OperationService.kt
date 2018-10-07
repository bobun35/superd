package operation

import budget.BudgetService
import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction

enum class OperationStatus { ONGOING, CLOSED }

enum class OperationType { DEBIT, CREDIT }

data class Operation(val id: Int,
                     val name: String,
                     val type: OperationType,
                     val amount: Float,
                     val status: OperationStatus,
                     val budgetId: Int,
                     val store: String,
                     val comment: String // commentaire sur l'opération
        //val creationDate: DateTime
)

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
            //val creationDate = date("creation_date")
            }
    }

    companion object: KLoggable {
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
        createOperationInDb("subvention 1", OperationType.CREDIT, 2304.09f,
                OperationStatus.CLOSED, budgetId, "Mairie", "1er versement")
        createOperationInDb("subvention 2", OperationType.DEBIT, 50f,
                OperationStatus.ONGOING, budgetId, "Sadel", "stylos")
    }

    fun createOperationInDb(name: String,
                            type: OperationType,
                            amount: Float,
                            status: OperationStatus,
                            budgetId: Int,
                            store: String,
                            comment: String? = null) {
        try {
            transaction {
                table.operations.insert {
                    it[table.operations.name] = name
                    it[table.operations.type] = type
                    it[table.operations.amount] = (amount*100).toInt()
                    it[table.operations.status] = status
                    it[table.operations.budgetId] = budgetId
                    it[table.operations.store] = store
                    it[table.operations.comment] = comment ?: ""
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
    }

    fun getAllOperationsByBudgetId(id: Int): List<Operation> {
        return getOperations { (table.operations.budgetId eq id) }
    }

    private fun getOperations(where: SqlExpressionBuilder.()-> Op<Boolean>): List<Operation> {
        var operations = mutableListOf<Operation>()
        try {
            transaction {
                val result = table.operations.select( where )
                for (row in result) {
                        operations.add( Operation(
                                        row[table.operations.id],
                                        row[table.operations.name],
                                        row[table.operations.type],
                                (row[table.operations.amount].toFloat())/100,
                                        row[table.operations.status],
                                        row[table.operations.budgetId],
                                        row[table.operations.store],
                                        row[table.operations.comment]
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

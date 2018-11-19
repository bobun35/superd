package operation

import budget.BudgetService
import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import org.joda.time.DateTime

const val OPERATION_TABLE_NAME = "operations"

enum class OperationStatus { ONGOING, CLOSED }


data class Operation(val id: Int,
                     val name: String,
                     val status: OperationStatus,
                     val budgetId: Int,
                     val store: String,
                     val comment: String?, // commentaire sur l'opération
                     val quotation: String?, // devis
                     val invoice: String?, // facture
                     val quotationDate: DateTime?,
                     val invoiceDate: DateTime?,
                     val quotationAmount: Int?,
                     val invoiceAmount: Int?
)

data class JsonOperation(val id: Int,
                         val name: String,
                         val store: String,
                         val comment: String?,
                         val quotation: String?,
                         val quotationDate: String?,
                         val quotationAmount: Int?,
                         val invoice: String?,
                         val invoiceDate: String?,
                         val invoiceAmount: Int?) {

    fun convertToOperation(budgetId: Int): Operation {
        return Operation(id = this.id,
                name = this.name,
                status = computeOperationStatus(),
                budgetId = budgetId,
                store = this.store,
                comment = this.comment,
                quotation = this.quotation,
                invoice = this.invoice,
                quotationDate = convertToDatetime(this.quotationDate),
                invoiceDate = convertToDatetime(this.invoiceDate),
                quotationAmount = this.quotationAmount,
                invoiceAmount = this.invoiceAmount)
    }

    private fun computeOperationStatus(): OperationStatus {
        if (this.invoiceAmount != null) {
            return OperationStatus.CLOSED
        }
        return OperationStatus.ONGOING
    }

    private fun convertToDatetime(jsonDate: String?): DateTime? {
        if (jsonDate == null) {
            return null
        }

        try {
            val (day, month, year) = jsonDate.split("/").map { it.toInt() }
            return DateTime(year, month, day, 0, 0, 0)
        } catch (exception: Exception) {
            throw IllegalArgumentException("operation date $jsonDate cannot be converted to Datetime")
        }

    }
}

fun List<Operation>.sumInvoiceAmounts(): Int {
    return this.mapNotNull { it.invoiceAmount }.sum()
}

fun List<Operation>.sumQuotationAmounts(): Int {
    return this.isOnGoingQuotation().mapNotNull { it.quotationAmount }.sum()
}

fun List<Operation>.isOnGoingQuotation(): List<Operation> {
    return this.filter { (it.quotationAmount !== null) and (it.invoiceAmount == null) }
}

class OperationService {

    object table {
        // object name and database table name shall be the same
        object operations : Table() {
            val id = integer("id").autoIncrement().primaryKey()
            val name = varchar("name", 100)
            val status = enumeration("status", OperationStatus::class.java)
            val budgetId = integer("budget_id") references BudgetService.table.budgets.id
            val store = varchar("store", 100)
            val comment = varchar("comment", 255)
            val quotation = varchar("quotation", 255).nullable() // reference devis
            val invoice = varchar("invoice", 255).nullable() // reference facture
            val quotationDate = date("quotation_date").nullable()
            val invoiceDate = date("invoice_date").nullable()
            val quotationAmount = integer("quotation_amount").nullable()
            val invoiceAmount = integer("invoice_amount").nullable()
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
        createOperationInDb("subvention 1", OperationStatus.CLOSED, budgetId, "Mairie", "1er versement",
                invoice = "versement initial",
                invoiceDate = DateTime(2018, 9, 1, 0, 0, 0),
                invoiceAmount = 230409)
        createOperationInDb("dépense 1", OperationStatus.CLOSED,
                budgetId, "Sadel", "stylos", "devis001", "facture001",
                DateTime(2018, 8, 20, 0, 0, 0),
                DateTime(2018, 10, 23, 0, 0, 0),
                quotationAmount = -50000, invoiceAmount = -50080)
        createOperationInDb("dépense 2", OperationStatus.ONGOING,
                budgetId, "Sadel", "peinture", "devis002", "facture002",
                DateTime(2018, 9, 18, 0, 0, 0),
                quotationAmount = -4300)
    }

    fun createOperationInDb(name: String,
                            status: OperationStatus,
                            budgetId: Int,
                            store: String,
                            comment: String? = null,
                            quotation: String? = null,
                            invoice: String? = null,
                            quotationDate: DateTime? = null,
                            invoiceDate: DateTime? = null,
                            quotationAmount: Int? = null,
                            invoiceAmount: Int? = null
    ) {
        try {
            transaction {
                table.operations.insert {
                    it[table.operations.name] = name
                    it[table.operations.status] = status
                    it[table.operations.budgetId] = budgetId
                    it[table.operations.store] = store
                    it[table.operations.comment] = comment ?: ""
                    it[table.operations.quotation] = quotation
                    it[table.operations.invoice] = invoice
                    it[table.operations.quotationDate] = quotationDate
                    it[table.operations.invoiceDate] = invoiceDate
                    it[table.operations.quotationAmount] = quotationAmount
                    it[table.operations.invoiceAmount] = invoiceAmount
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
    }

    fun getAllOperationsByBudgetId(id: Int): List<Operation> {
        return getOperations { (table.operations.budgetId eq id) }.sortedByDescending { it.id }
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
                            row[table.operations.status],
                            row[table.operations.budgetId],
                            row[table.operations.store],
                            row[table.operations.comment],
                            row[table.operations.quotation],
                            row[table.operations.invoice],
                            row[table.operations.quotationDate],
                            row[table.operations.invoiceDate],
                            row[table.operations.quotationAmount],
                            row[table.operations.invoiceAmount]
                    ))
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
        return operations
    }

    private fun getOperation(id: Int): Operation {
        val operations = getOperations { table.operations.id eq id }
        if (operations.size != 1) {
            throw NoSuchElementException(" $operations.size operations with id $id have been found")
        }
        return operations.first()
    }

    fun modifyAllFields(operation: Operation) {
        try {
            transaction {
                table.operations.update({ table.operations.id eq operation.id }) {
                    it[name] = operation.name
                    it[status] = operation.status
                    it[store] = operation.store
                    it[comment] = operation.comment ?: ""
                    it[quotation] = operation.quotation
                    it[invoice] = operation.invoice
                    it[quotationDate] = operation.quotationDate
                    it[invoiceDate] = operation.invoiceDate
                    it[quotationAmount] = operation.quotationAmount
                    it[invoiceAmount] = operation.invoiceAmount
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
            throw exception
        }
    }
}

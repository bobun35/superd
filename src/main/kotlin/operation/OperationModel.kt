package operation

import mu.KLoggable
import org.joda.time.DateTime

class OperationModel {

    val operationService = OperationService()

    companion object : KLoggable {
        override val logger = logger()
    }

    fun getAllOperationsFromBudgetId(id: Int): List<Operation> {
        return operationService.getAllOperationsByBudgetId(id)
    }

    fun updateAllFields(operation: Operation) {
        try {
            // TODO ajouter une vérification sur le budgetId
            operationService.modifyAllFields(operation)
        } catch (exception: Exception) {
            logger.error { "operation $operation.id has not been updated"}
            throw exception
        }
    }

    fun createOperation(budgetId: Int, operation: Operation) {
        operationService.createOperationInDb(
                name = operation.name,
                status = operation.status,
                budgetId = budgetId,
                store = operation.store,
                comment = operation.comment,
                quotation = operation.quotation,
                invoice = operation.invoice,
                quotationDate = operation.quotationDate,
                invoiceDate = operation.invoiceDate,
                quotationAmount = operation.quotationAmount,
                invoiceAmount = operation.invoiceAmount)
    }

}
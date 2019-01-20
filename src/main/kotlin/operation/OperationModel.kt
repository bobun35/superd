package operation

import mu.KLoggable

class OperationModel {

    val operationService = OperationService()

    companion object : KLoggable {
        override val logger = logger()
    }

    fun getAllOperationsFromBudgetId(id: Int): List<Operation> {
        return operationService.getByBudgetId(id)
    }

    fun updateAllFields(operation: Operation) {
        try {
            // TODO ajouter une vérification sur le budgetId
            operationService.updateAllFields(operation)
        } catch (exception: Exception) {
            logger.error { "operation $operation.id has not been updated"}
            throw exception
        }
    }

    fun createOperation(budgetId: Int, operation: Operation) {
        operationService.createInDb(
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

    fun deleteOperation(budgetId: Int, operationId: Int) {
        val operationToDelete = operationService.getById(operationId)

        if (operationToDelete.budgetId != budgetId) {
            logger.error("Tried to delete operation $operationId of budget $budgetId. " +
                    "But this operation does not belong to this budget")
            throw IllegalArgumentException("Could not delete operation")
        }

        operationService.deleteById(operationId)
    }

}
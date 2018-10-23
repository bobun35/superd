package operation

import mu.KLoggable

class OperationModel {

    val operationService = OperationService()

    companion object : KLoggable {
        override val logger = logger()
    }

    fun getAllOperationsFromBudgetId(id: Int): List<Operation> {
        return operationService.getAllOperationsByBudgetId(id)
    }

}
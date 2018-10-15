package budget

import mu.KLoggable
import operation.Operation
import operation.OperationModel
import operation.sumAmounts
import kotlin.math.round

class BudgetModel {

    val budgetService = BudgetService()
    val operationModel = OperationModel()

    companion object : KLoggable {
        override val logger = logger()
    }

    fun getBudgetSummariesFromSchoolId(id: Int): List<BudgetSummary> {
        return budgetService.getBudgetIdsBySchoolId(id)
                .map { getBudgetById(it)}
                .map { BudgetSummary.createFromBudget(it) }
    }

    fun getBudgetById(id: Int): Budget {
        val budget = budgetService.getBudgetById(id)

        budget.operations = operationModel.getAllOperationsFromBudgetId(budget.id)
        budget.virtualRemaining = budget.operations.sumAmounts()

        val realOperations = operationModel.getAlreadyPaidOperationsFromBudgetId(budget.id)
        budget.realRemaining = realOperations.sumAmounts()

        return budget
    }

    fun getFirstBudgetIdBySchoolReference(reference:String): Int {
        return budgetService.getBudgetBySchoolReference(reference)!!.first().id
    }
}
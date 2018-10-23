package budget

import mu.KLoggable
import operation.*
import kotlin.math.round

class BudgetModel {

    val budgetService = BudgetService()
    val operationModel = OperationModel()

    companion object : KLoggable {
        override val logger = logger()
    }

    fun getBudgetSummariesFromSchoolId(id: Int): List<BudgetSummary> {
        return budgetService.getBudgetIdsBySchoolId(id)
                .map { getBudgetById(it) }
                .map { BudgetSummary.createFromBudget(it) }
    }

    fun getBudgetById(id: Int): Budget {
        val budget = budgetService.getBudgetById(id)

        budget.operations = operationModel.getAllOperationsFromBudgetId(budget.id)
        val invoicesSum =  budget.operations.sumInvoiceAmounts().toFloat() / 100
        val quotationsSum =  budget.operations.sumQuotationAmounts().toFloat() / 100

        budget.virtualRemaining = invoicesSum + quotationsSum
        budget.realRemaining = invoicesSum

        return budget
    }

    fun getFirstBudgetIdBySchoolReference(reference: String): Int {
        return budgetService.getBudgetBySchoolReference(reference)!!.first().id
    }
}
package budget

import mu.KLoggable
import operation.*
import java.util.*
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
        val invoicesSum =  number2digits(budget.operations.sumInvoiceAmounts().toDouble() / 100)
        val quotationsSum =  number2digits(budget.operations.sumQuotationAmounts().toDouble() / 100)

        budget.virtualRemaining = number2digits(invoicesSum + quotationsSum)
        budget.realRemaining = invoicesSum

        return budget
    }

    fun number2digits(number: Double):Double {
        return String.format(Locale.ENGLISH, "%.2f", number).toDouble()
    }

    fun getFirstBudgetIdBySchoolReference(reference: String): Int {
        return budgetService.getBudgetBySchoolReference(reference)!!.first().id
    }
}
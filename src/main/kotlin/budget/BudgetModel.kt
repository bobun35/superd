package budget

import mu.KLoggable

class BudgetModel {

    val budgetService = BudgetService()

    companion object : KLoggable {
        override val logger = logger()
    }

    fun getBudgetSummariesFromSchoolId(id: Int): List<BudgetSummary> {
        return budgetService.getBudgetsBySchoolId(id).map { BudgetSummary.createFromBudget(it) }
    }

    fun getBudgetById(id: Int): Budget {
        return budgetService.getBudgetById(id)
    }

    fun getFirstBudgetIdBySchoolReference(reference:String): Int {
        return budgetService.getBudgetBySchoolReference(reference)!!.first().id
    }
}
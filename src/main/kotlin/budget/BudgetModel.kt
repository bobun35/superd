package budget

import mu.KLoggable

class BudgetModel {

    val budgetService = BudgetService()

    companion object : KLoggable {
        override val logger = logger()
    }

    fun getBudgetsFromSchoolId(id: Int): List<Budget> {
        return budgetService.getBudgetsBySchoolId(id)
    }

    fun getBudgetById(id: Int): Budget {
        return budgetService.getBudgetById(id)
    }
}
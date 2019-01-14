package budget

data class BudgetSummary(val id: Int,
                         val name: String,
                         val reference: String, // reference comptable
                         val type: String, // e.g. fonctionnement, investissement
                         val recipient: String, // e.g. maternelle, primaire, général
                         val realRemaining: Double = 0.0, // reste réel (commandes en cours non prise en compte)
                         val virtualRemaining: Double = 0.0 // reste virtuel (commandes en cours déduites)
) {
    private val budgetTypeService = BudgetTypeService()

    companion object {
        fun createFromBudget(budget: Budget): BudgetSummary {

            val budgetTypeName = BudgetTypeService().getName(budget.type)

            return BudgetSummary(
                    budget.id,
                    budget.name,
                    budget.reference,
                    budgetTypeName,
                    budget.recipient,
                    budget.realRemaining,
                    budget.virtualRemaining)
        }
    }
}
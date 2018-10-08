package budget

data class BudgetSummary(val id: Int,
                         val name: String,
                         val reference: String, // reference comptable
                         val type: String, // e.g. fonctionnement, investissement
                         val recipient: String, // e.g. maternelle, primaire, général
                         val realRemaining: Float = 0f, // reste réel (commandes en cours non prise en compte)
                         val virtualRemaining: Float = 0f // reste virtuel (commandes en cours déduites)
) {
    companion object {
        fun createFromBudget(budget: Budget): BudgetSummary {
            return BudgetSummary(budget.id, budget.name, budget.reference, budget.type, budget.recipient,
                    budget.realRemaining, budget.virtualRemaining)
        }
    }
}
package budget

data class BudgetSummary(val id: Int,
                         val name: String,
                         val reference: String, // reference comptable
                         val type: String, // e.g. fonctionnement, investissement
                         val recipient: String, // e.g. maternelle, primaire, général
                         val realRemaining: Double = 0.0, // reste réel (commandes en cours non prise en compte)
                         val virtualRemaining: Double = 0.0 // reste virtuel (commandes en cours déduites)
) {
    companion object {
        fun createFromBudget(budget: Budget): BudgetSummary {

            val budgetType = BudgetTypeService().getName(budget.typeId)
            val recipient = RecipientService().getName(budget.recipientId)

            return BudgetSummary(
                    budget.id,
                    budget.name,
                    budget.reference,
                    budgetType,
                    recipient,
                    budget.realRemaining,
                    budget.virtualRemaining)
        }
    }
}
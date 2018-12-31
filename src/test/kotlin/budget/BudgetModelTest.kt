package budget

import io.kotlintest.specs.StringSpec
import DatabaseListener
import TEST_SCHOOL_REFERENCE
import io.kotlintest.shouldBe
import io.kotlintest.shouldThrow
import populateDbWithBudgets
import populateDbWithOperations


class BudgetModelTest : StringSpec() {
    private val budgetModel = BudgetModel()

    override fun listeners() = listOf(DatabaseListener)

    init {

        "getBudgetById should return virtual and real remaining" {
            populateDbWithOperations()

            val budgetId1 = budgetModel.getFirstBudgetIdBySchoolReference(TEST_SCHOOL_REFERENCE)
            val budget1 = budgetModel.getBudgetById(budgetId1)

            budget1.operations.size shouldBe 5
            budget1.realRemaining shouldBe 3174.09
            budget1.virtualRemaining shouldBe 2540.07
        }

        "modifyAllFields should not update budget if shoolId is not the expected one" {
            populateDbWithBudgets()
            val budgetId1 = budgetModel.getFirstBudgetIdBySchoolReference(TEST_SCHOOL_REFERENCE)
            val budget1 = budgetModel.getBudgetById(budgetId1)

            val fakeSchoolId = 98989898
            shouldThrow<java.lang.IllegalArgumentException> {
                budgetModel.updateAllFields(fakeSchoolId, budget1.id, budget1.name, budget1.reference,
                        budget1.type, budget1.recipient, budget1.creditor, "new comment from test")
            }

            val actualBudget = budgetModel.getBudgetById(budgetId1)
            budgetsAreEqual(budget1, actualBudget) shouldBe true

            budgetModel.updateAllFields(budget1.schoolId, budget1.id, budget1.name, budget1.reference,
                    budget1.type, budget1.recipient, budget1.creditor, "new comment from test")

            val updatedBudget = budgetModel.getBudgetById(budgetId1)
            budgetsAreEqual(budget1, updatedBudget) shouldBe false
            updatedBudget.comment shouldBe "new comment from test"

        }
    }

}
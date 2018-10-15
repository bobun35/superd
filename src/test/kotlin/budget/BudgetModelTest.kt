package budget

import io.kotlintest.specs.StringSpec
import DatabaseListener
import TEST_SCHOOL_REFERENCE
import io.kotlintest.shouldBe
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
            budget1.realRemaining shouldBe 2361.09
            budget1.virtualRemaining shouldBe 2540.07
        }
    }

}
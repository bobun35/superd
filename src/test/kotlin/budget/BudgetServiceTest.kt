package budget

import io.kotlintest.specs.StringSpec
import DatabaseListener
import TEST_SCHOOL_REFERENCE
import io.kotlintest.matchers.boolean.shouldBeTrue
import populateDbWithSchools
import school.SchoolService


class BudgetServiceTest : StringSpec() {
    private val budgetService = BudgetService()

    private val testName = "testName"
    private val testReference = "testReference"

    override fun listeners() = listOf(DatabaseListener)

    init {

        "budget creation and get should succeed" {
            populateDbWithSchools()
            budgetService.createBudgetInDb(testName, testReference, TEST_SCHOOL_REFERENCE)
            val schoolService = SchoolService()
            val actualSchoolId = schoolService.getSchoolByReference(TEST_SCHOOL_REFERENCE)

            val expectedBudget = Budget(0, testName, testReference)
            val actualBudget = budgetService.getBudgetsBySchoolId(actualSchoolId!!.id)
            budgetsAreEqual(actualBudget[0], expectedBudget).shouldBeTrue()
        }
    }

}

fun budgetsAreEqual(budget1: Budget?, budget2: Budget?): Boolean {
    return budget1?.name == budget2?.name &&
           budget1?.reference == budget2?.reference
}
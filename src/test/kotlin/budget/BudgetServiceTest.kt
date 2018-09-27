package budget

import io.kotlintest.specs.StringSpec
import DatabaseListener
import TEST_SCHOOL_REFERENCE
import io.kotlintest.matchers.boolean.shouldBeTrue
import populateDbWithSchools
import school.SchoolService


class BudgetServiceTest : StringSpec() {
    private val schoolService = SchoolService()
    private val budgetService = BudgetService()

    private val testName = "testName"
    private val testReference = "testReference"

    override fun listeners() = listOf(DatabaseListener)

    init {

        "budget creation and get should succeed" {
            populateDbWithSchools()
            val school = schoolService.getSchoolByReference(TEST_SCHOOL_REFERENCE)
            val schoolId = school!!.id
            val expectedBudget = Budget(0, testName, testReference, Status.OPEN, schoolId)

            budgetService.createBudgetInDb(testName, testReference, TEST_SCHOOL_REFERENCE)

            val actualBudget = budgetService.getBudgetsBySchoolId(schoolId)
            budgetsAreEqual(actualBudget[0], expectedBudget).shouldBeTrue()
        }
    }

}

fun budgetsAreEqual(budget1: Budget?, budget2: Budget?): Boolean {
    return budget1?.name == budget2?.name
            && budget1?.reference == budget2?.reference
            && budget1?.status == budget2?.status
            && budget1?.schoolId == budget2?.schoolId
}
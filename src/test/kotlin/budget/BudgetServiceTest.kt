package budget

import io.kotlintest.specs.StringSpec
import DatabaseListener
import TEST_BUDGET1
import TEST_SCHOOL_REFERENCE
import io.kotlintest.matchers.boolean.shouldBeTrue
import populateDbWithBudgets
import populateDbWithSchools
import school.SchoolService


class BudgetServiceTest : StringSpec() {
    private val schoolService = SchoolService()
    private val budgetService = BudgetService()

    private val testName = TEST_BUDGET1.get("name")!!
    private val testReference = TEST_BUDGET1.get("reference")!!

    override fun listeners() = listOf(DatabaseListener)

    init {

        "budget creation and get should succeed" {
            populateDbWithSchools()
            val school = schoolService.getSchoolByReference(TEST_SCHOOL_REFERENCE)
            val schoolId = school!!.id
            val expectedBudget = Budget(0, testName, testReference, Status.OPEN, schoolId, BUDGET_DEFAULT_TYPE,
                    BUDGET_DEFAULT_RECIPIENT, BUDGET_DEFAULT_CREDITOR, BUDGET_DEFAULT_COMMENT)

            budgetService.createBudgetInDb(testName, testReference, TEST_SCHOOL_REFERENCE)

            val actualBudget = budgetService.getBudgetsBySchoolId(schoolId)
            budgetsAreEqual(actualBudget[0], expectedBudget).shouldBeTrue()
        }

        "budget update should succeed" {
            populateDbWithBudgets()
            val schoolRef = TEST_BUDGET1.get("schoolReference")!!
            val school = schoolService.getSchoolByReference(schoolRef)
            val schoolId = school!!.id

            val expectedBudget = Budget(0
                    , TEST_BUDGET1.get("name")!!
                    , TEST_BUDGET1.get("reference")!!
                    , Status.OPEN
                    , schoolId
                    , TEST_BUDGET1.get("type")!!
                    , TEST_BUDGET1.get("recipient")!!
                    , "my new creditor"
                    , TEST_BUDGET1.get("comment")!!)

            val actualBudgetId = budgetService.getBudgetsBySchoolId(schoolId)[0].id
            budgetService.modifyAllFields(actualBudgetId
                    , expectedBudget.name
                    , expectedBudget.reference
                    , expectedBudget.type
                    , expectedBudget.recipient
                    , expectedBudget.creditor
                    , expectedBudget.comment)

            val actualBudget = budgetService.getBudgetsBySchoolId(schoolId)[0]
            budgetsAreEqual(actualBudget, expectedBudget).shouldBeTrue()
        }
    }

}

fun budgetsAreEqual(budget1: Budget?, budget2: Budget?): Boolean {
    return budget1?.name == budget2?.name
            && budget1?.reference == budget2?.reference
            && budget1?.status == budget2?.status
            && budget1?.schoolId == budget2?.schoolId
            && budget1?.type == budget2?.type
            && budget1?.recipient == budget2?.recipient
            && budget1?.creditor == budget2?.creditor
            && budget1?.comment == budget2?.comment }
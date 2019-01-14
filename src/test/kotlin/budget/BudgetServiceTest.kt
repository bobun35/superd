package budget

import io.kotlintest.specs.StringSpec
import DatabaseListener
import TEST_BUDGET1
import TEST_SCHOOL_REFERENCE
import arrow.core.Tuple2
import io.kotlintest.matchers.boolean.shouldBeTrue
import populateDbWithBudgetTypes
import populateDbWithBudgets
import populateDbWithSchools
import school.SchoolService


class BudgetServiceTest : StringSpec() {
    private val budgetService = BudgetService()
    private val budgetTypeService = BudgetTypeService()

    private val testName = TEST_BUDGET1.get("name")!!
    private val testReference = TEST_BUDGET1.get("reference")!!

    override fun listeners() = listOf(DatabaseListener)

    init {

        "budget creation and get should succeed" {
            populateDbWithBudgetTypes()
            val (schoolId, budgetTypeId) = getSchoolAndBudgetType(TEST_SCHOOL_REFERENCE, BUDGET_DEFAULT_TYPE)

            val expectedBudget = Budget(0, testName, testReference, Status.OPEN, schoolId, budgetTypeId,
                    BUDGET_DEFAULT_RECIPIENT, BUDGET_DEFAULT_CREDITOR, BUDGET_DEFAULT_COMMENT)

            budgetService.createBudgetInDb(testName, testReference, schoolId, budgetTypeId)

            val actualBudget = budgetService.getBudgetsBySchoolId(schoolId)
            budgetsAreEqual(actualBudget[0], expectedBudget).shouldBeTrue()
        }

        "budget update should succeed" {
            populateDbWithBudgets()
            val (schoolId, budgetTypeId) = getSchoolAndBudgetType(TEST_BUDGET1["schoolReference"]!!,
                    BUDGET_DEFAULT_TYPE)

            val expectedBudget = Budget(0
                    , TEST_BUDGET1["name"]!!
                    , TEST_BUDGET1["reference"]!!
                    , Status.OPEN
                    , schoolId
                    , budgetTypeId
                    , TEST_BUDGET1["recipient"]!!
                    , "my new creditor"
                    , TEST_BUDGET1["comment"]!!)

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

fun getSchoolAndBudgetType(schoolReference: String, budgetType: String): Tuple2<Int, Int> {
    val school = SchoolService().getSchoolByReference(schoolReference)
    val schoolId = school!!.id

    val budgetType = BudgetTypeService().getBySchoolIdAndName(schoolId, budgetType)
    val budgetTypeId = budgetType!!.id

    return Tuple2(schoolId, budgetTypeId)

}

fun budgetsAreEqual(budget1: Budget?, budget2: Budget?): Boolean {
    return budget1?.name == budget2?.name
            && budget1?.reference == budget2?.reference
            && budget1?.status == budget2?.status
            && budget1?.schoolId == budget2?.schoolId
            && budget1?.type == budget2?.type
            && budget1?.recipient == budget2?.recipient
            && budget1?.creditor == budget2?.creditor
            && budget1?.comment == budget2?.comment
}
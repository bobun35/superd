package budget

import io.kotlintest.specs.StringSpec
import DatabaseListener
import TEST_BUDGET1
import TEST_SCHOOL_REFERENCE
import arrow.core.Tuple2
import arrow.core.Tuple4
import io.kotlintest.matchers.boolean.shouldBeTrue
import populateDbWithBudgetTypes
import populateDbWithBudgets
import school.SchoolService


class BudgetServiceTest : StringSpec() {
    private val budgetService = BudgetService()

    private val testName = TEST_BUDGET1.get("name")!!
    private val testReference = TEST_BUDGET1.get("reference")!!

    override fun listeners() = listOf(DatabaseListener)

    init {

        "budget creation and get should succeed" {
            populateDbWithBudgetTypes()
            val (schoolId, budgetTypeId, recipientId, creditorId) =
                    getSchoolAndBudgetType(TEST_SCHOOL_REFERENCE,
                            BUDGET_DEFAULT_TYPE,
                            BUDGET_DEFAULT_RECIPIENT,
                            BUDGET_DEFAULT_CREDITOR)

            val expectedBudget = Budget(0, testName, testReference, Status.OPEN, schoolId, budgetTypeId,
                    recipientId, creditorId, BUDGET_DEFAULT_COMMENT)

            budgetService.createInDb(testName, testReference, schoolId, budgetTypeId, recipientId, creditorId)

            val actualBudget = budgetService.getBySchoolId(schoolId)
            budgetsAreEqual(actualBudget[0], expectedBudget).shouldBeTrue()
        }

        "budget update should succeed" {
            populateDbWithBudgets()
            val (schoolId, budgetTypeId, recipientId, creditorId) =
                    getSchoolAndBudgetType(TEST_BUDGET1["schoolReference"]!!,
                            BUDGET_DEFAULT_TYPE,
                            BUDGET_DEFAULT_RECIPIENT,
                            BUDGET_DEFAULT_CREDITOR)

            val expectedBudget = Budget(0
                    , TEST_BUDGET1["name"]!!
                    , TEST_BUDGET1["reference"]!!
                    , Status.OPEN
                    , schoolId
                    , budgetTypeId
                    , recipientId
                    , creditorId
                    , TEST_BUDGET1["comment"]!!)

            val actualBudgetId = budgetService.getBySchoolId(schoolId)[0].id
            budgetService.modifyAllFields(actualBudgetId
                    , expectedBudget.name
                    , expectedBudget.reference
                    , expectedBudget.typeId
                    , expectedBudget.recipientId
                    , expectedBudget.creditorId
                    , expectedBudget.comment)

            val actualBudget = budgetService.getBySchoolId(schoolId)[0]
            budgetsAreEqual(actualBudget, expectedBudget).shouldBeTrue()
        }
    }

}

fun getSchoolAndBudgetType(schoolReference: String,
                           budgetType: String,
                           recipient: String,
                           creditor: String): Tuple4<Int, Int, Int, Int> {
    val school = SchoolService().getByReference(schoolReference)
    val schoolId = school!!.id

    val budgetType = BudgetTypeService().getBySchoolIdAndName(schoolId, budgetType)
    val budgetTypeId = budgetType!!.id

    val recipient = RecipientService().getBySchoolIdAndName(schoolId, recipient)
    val recipientId = recipient!!.id

    val creditor = CreditorService().getBySchoolIdAndName(schoolId, creditor)
    val creditorId = creditor!!.id

    return Tuple4(schoolId, budgetTypeId, recipientId, creditorId)

}

fun budgetsAreEqual(budget1: Budget?, budget2: Budget?): Boolean {
    return budget1?.name == budget2?.name
            && budget1?.reference == budget2?.reference
            && budget1?.status == budget2?.status
            && budget1?.schoolId == budget2?.schoolId
            && budget1?.typeId == budget2?.typeId
            && budget1?.recipientId == budget2?.recipientId
            && budget1?.creditorId == budget2?.creditorId
            && budget1?.comment == budget2?.comment
}
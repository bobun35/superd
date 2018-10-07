package operation

import io.kotlintest.specs.StringSpec
import DatabaseListener
import TEST_SCHOOL_REFERENCE
import budget.BudgetService
import io.kotlintest.matchers.boolean.shouldBeTrue
import populateDbWithBudgets
import school.SchoolService


class OperationServiceTest : StringSpec() {
    private val schoolService = SchoolService()
    private val budgetService = BudgetService()
    private val operationService = OperationService()

    override fun listeners() = listOf(DatabaseListener)

    init {

        "budget creation and get should succeed" {
            populateDbWithBudgets()
            val schoolId = schoolService.getSchoolByReference(TEST_SCHOOL_REFERENCE)!!.id
            val budgetId = budgetService.getBudgetsBySchoolId(schoolId).first()!!.id
            val expectedOperation = Operation(0, "operationTestName", OperationType.CREDIT, 2304.09f,
                    OperationStatus.ONGOING, budgetId, "testStore", "test comment")

            operationService.createOperationInDb("operationTestName", OperationType.CREDIT, 2304.09f,
                    OperationStatus.ONGOING, budgetId, "testStore", "test comment")

            val actualOperations = operationService.getAllOperationsByBudgetId(budgetId)
            operationsAreEqual(actualOperations[0], expectedOperation).shouldBeTrue()
        }
    }

}

fun operationsAreEqual(operation1: Operation?, operation2: Operation?): Boolean {
    return operation1?.name == operation2?.name
            && operation1?.type == operation2?.type
            && operation1?.amount == operation2?.amount
            && operation1?.status == operation2?.status
            && operation1?.budgetId == operation2?.budgetId
            && operation1?.store == operation2?.store
            && operation1?.comment== operation2?.comment }
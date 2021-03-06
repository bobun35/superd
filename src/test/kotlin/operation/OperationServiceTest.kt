package operation

import io.kotlintest.specs.StringSpec
import DatabaseListener
import TEST_SCHOOL_REFERENCE
import budget.BudgetService
import io.kotlintest.matchers.boolean.shouldBeTrue
import io.kotlintest.matchers.collections.contain
import io.kotlintest.shouldBe
import io.kotlintest.shouldNot
import org.joda.time.DateTime
import populateDbWithBudgets
import populateDbWithOperations
import school.SchoolService


class OperationServiceTest : StringSpec() {
    private val schoolService = SchoolService()
    private val budgetService = BudgetService()
    private val operationService = OperationService()

    override fun listeners() = listOf(DatabaseListener)

    init {

        "operation creation with only quotation and get it should succeed" {
            populateDbWithBudgets()
            val schoolId = schoolService.getByReference(TEST_SCHOOL_REFERENCE)!!.id
            val budgetId = budgetService.getBySchoolId(schoolId).first()!!.id
            val expectedOperation = Operation(0, "operationTestName",
                    OperationStatus.ONGOING, budgetId, "testStore", "test comment",
                    "devis001", null,
                    DateTime(2018, 9, 23, 0, 0, 0),
                    null, 45678, null
            )

            operationService.createInDb("operationTestName",
                    OperationStatus.ONGOING, budgetId, "testStore",
                    "test comment", "devis001", null,
                    DateTime(2018, 9, 23, 0, 0, 0),
                    null, 45678, null
            )

            val actualOperations = operationService.getByBudgetId(budgetId)
            operationsAreEqual(actualOperations[0], expectedOperation).shouldBeTrue()
        }

        "operation creation with only invoice and get it should succeed" {
            populateDbWithBudgets()
            val schoolId = schoolService.getByReference(TEST_SCHOOL_REFERENCE)!!.id
            val budgetId = budgetService.getBySchoolId(schoolId).first()!!.id
            val expectedOperation = Operation(0, "operationTestName",
                    OperationStatus.ONGOING, budgetId, "testStore", "test comment",
                    quotation = null,
                    invoice = "facture001",
                    quotationDate = null,
                    invoiceDate = DateTime(2018, 9, 23, 0, 0, 0),
                    quotationAmount = null,
                    invoiceAmount = 45678
            )

            operationService.createInDb(name = "operationTestName",
                    status = OperationStatus.ONGOING,
                    budgetId = budgetId,
                    store = "testStore",
                    comment = "test comment",
                    quotation = null,
                    invoice = "facture001",
                    quotationDate = null,
                    invoiceDate = DateTime(2018, 9, 23, 0, 0, 0),
                    quotationAmount = null, invoiceAmount = 45678
            )

            val actualOperations = operationService.getByBudgetId(budgetId)
            operationsAreEqual(actualOperations[0], expectedOperation).shouldBeTrue()
        }

        "convertFromJsonOperation should succeed in converting a jsonOperation" {
            val jsonOperationTest = JsonOperation(  id = 3,
                                                    name = "test",
                                                    store = "Sadel",
                                                    comment = null,
                                                    quotation = "quotationReference",
                                                    quotationDate = "12/01/2017",
                                                    quotationAmount = -669,
                                                    invoice = null,
                                                    invoiceDate = null,
                                                    invoiceAmount = null)

            val expectedOperation = Operation(  id = 3,
                                                name = "test",
                                                status = OperationStatus.ONGOING,
                                                budgetId = 44,
                                                store = "Sadel",
                                                comment = null,
                                                quotation = "quotationReference",
                                                quotationDate = DateTime(2017, 1, 12, 0, 0, 0),
                                                quotationAmount = -669,
                                                invoice = null,
                                                invoiceDate = null,
                                                invoiceAmount = null)

            val actualOperation = jsonOperationTest.convertToOperation(44)
            operationsAreEqual(actualOperation, expectedOperation).shouldBeTrue()
            actualOperation.id shouldBe expectedOperation.id
        }

        "deleteOperation should succeed" {
            populateDbWithOperations()
            val schoolId = schoolService.getByReference(TEST_SCHOOL_REFERENCE)!!.id
            val budgetId = budgetService.getBySchoolId(schoolId).first()!!.id

            val initialOperations = operationService.getByBudgetId(budgetId)
            val initialOperationsCount = initialOperations.size

            val operationIdToDelete = initialOperations.first().id!!
            operationService.deleteById(operationIdToDelete)

            val actualOperations = operationService.getByBudgetId(budgetId)

            actualOperations.size shouldBe initialOperationsCount - 1

            val actualOperationsIds = actualOperations.map { it.id }
            actualOperationsIds shouldNot contain(operationIdToDelete)
        }

        "getOperationById should return right operation" {
            populateDbWithOperations()
            val schoolId = schoolService.getByReference(TEST_SCHOOL_REFERENCE)!!.id
            val budgetId = budgetService.getBySchoolId(schoolId).first()!!.id

            val initialOperations = operationService.getByBudgetId(budgetId)
            val operationIdToGet = initialOperations.first().id!!

            val actualOperation = operationService.getById(operationIdToGet)

            actualOperation shouldBe initialOperations.first()
        }
    }

}

fun operationsAreEqual(operation1: Operation?, operation2: Operation?): Boolean {
    return operation1?.name == operation2?.name
            && operation1?.status == operation2?.status
            && operation1?.budgetId == operation2?.budgetId
            && operation1?.store == operation2?.store
            && operation1?.comment == operation2?.comment
            && operation1?.invoice == operation2?.invoice
            && operation1?.quotation == operation2?.quotation
            && operation1?.quotationDate == operation2?.quotationDate
            && operation1?.invoiceDate == operation2?.invoiceDate
            && operation1?.quotationAmount == operation2?.quotationAmount
            && operation1?.invoiceAmount == operation2?.invoiceAmount
}
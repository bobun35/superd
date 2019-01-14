package budget

import mu.KLoggable
import operation.*
import java.util.*
import kotlin.NoSuchElementException

class BudgetModel {

    val budgetService = BudgetService()
    val budgetTypeService = BudgetTypeService()
    val operationModel = OperationModel()

    companion object : KLoggable {
        override val logger = logger()
    }

    fun getBudgetSummariesFromSchoolId(id: Int): List<BudgetSummary> {
        return budgetService.getBudgetIdsBySchoolId(id)
                .map { getBudgetById(it) }
                .map { BudgetSummary.createFromBudget(it) }
    }

    fun getBudgetById(id: Int): Budget {
        val budget = budgetService.getBudgetById(id)

        budget.operations = operationModel.getAllOperationsFromBudgetId(budget.id)
        val invoicesSum = number2digits(budget.operations.sumInvoiceAmounts().toDouble() / 100)
        val quotationsSum = number2digits(budget.operations.sumQuotationAmounts().toDouble() / 100)

        budget.virtualRemaining = number2digits(invoicesSum + quotationsSum)
        budget.realRemaining = invoicesSum

        return budget
    }

    fun number2digits(number: Double): Double {
        return String.format(Locale.ENGLISH, "%.2f", number).toDouble()
    }

    fun getFirstBudgetIdBySchoolReference(reference: String): Int {
        return budgetService.getBudgetBySchoolReference(reference)!!.first().id
    }

    fun updateAllFields(schoolId: Int,
                        budgetId: Int,
                        name: String,
                        reference: String,
                        type: String,
                        recipient: String,
                        creditor: String,
                        comment: String) {
        try {

            // Check schoolId
            val budgetToUpdate = getBudgetById(budgetId)
            if (budgetToUpdate.schoolId !== schoolId) {
                throw IllegalArgumentException("budget with id: $budgetId does not belong to school with id: $schoolId")
            }

            // Get budgetTypeId
            val budgetTypeId =
                    try {
                        budgetTypeService.getBySchoolIdAndName(schoolId, type).id
                    } catch (exception: NoSuchElementException) {
                        throw NoSuchElementException("budgetType with name: $type does not belong exist for school with id: $schoolId")
                    }

            // Update
            budgetService.modifyAllFields(budgetId,
                    name,
                    reference,
                    budgetTypeId,
                    recipient,
                    creditor,
                    comment)
        } catch (exception: Exception) {
            logger.error { "budget $budgetId has not been updated" }
            throw exception
        }
    }

    fun createBudget(name: String,
                     reference: String,
                     schoolId: Int,
                     type: String,
                     recipient: String?,
                     creditor: String?,
                     comment: String?): Int {
        val budgetTypeId = BudgetTypeService().getBySchoolIdAndName(schoolId, type).id
        return budgetService.createBudgetInDb(name, reference, schoolId,
                budgetTypeId, recipient, creditor, comment)
                ?: throw RuntimeException("Id of new budget is null after insert statement")
    }

    fun convertToBudgetForIHM(budget: Budget): BudgetForIHM {
        val budgetType = budgetTypeService.getName(budget.type)
        return BudgetForIHM(
                budget.id,
                budget.name,
                budget.reference,
                budget.schoolId,
                budgetType,
                budget.recipient,
                budget.creditor,
                budget.comment,
                budget.realRemaining,
                budget.virtualRemaining,
                budget.operations
                )
    }

    fun getTypes(schoolId: Int): List<BudgetType> {
        val types = budgetTypeService.getBySchoolId(schoolId)
        if (types.isEmpty()) {
            throw NoSuchElementException("no budget types found for school: $schoolId")
        }
        return types
    }
}

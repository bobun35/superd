package budget

import mu.KLoggable
import operation.*
import java.util.*
import kotlin.NoSuchElementException

class BudgetModel {

    val budgetService = BudgetService()
    val budgetTypeService = BudgetTypeService()
    val recipientService = RecipientService()
    val creditorService = CreditorService()
    private val operationModel = OperationModel()

    companion object : KLoggable {
        override val logger = logger()
    }

    fun getBudgetSummariesFromSchoolId(id: Int): List<BudgetSummary> {
        return budgetService.getBudgetIdsBySchoolId(id)
                .map { getBudgetById(it) }
                .map { BudgetSummary.createFromBudget(it) }
                .sortedBy { it.name }
    }

    fun getBudgetById(id: Int): Budget {
        val budget = budgetService.getById(id)

        budget.operations = operationModel.getAllOperationsFromBudgetId(budget.id)
        val invoicesSum = number2digits(budget.operations.sumInvoiceAmounts().toDouble() / 100)
        val quotationsSum = number2digits(budget.operations.sumQuotationAmounts().toDouble() / 100)

        budget.virtualRemaining = number2digits(invoicesSum + quotationsSum)
        budget.realRemaining = invoicesSum

        return budget
    }

    private fun number2digits(number: Double): Double {
        return String.format(Locale.ENGLISH, "%.2f", number).toDouble()
    }

    fun getFirstBudgetIdBySchoolReference(reference: String): Int {
        return budgetService.getBySchoolReference(reference)!!.first().id
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

            // Get RecipientId
            val recipientId =
                    try {
                        recipientService.getBySchoolIdAndName(schoolId, recipient).id
                    } catch (exception: NoSuchElementException) {
                        throw NoSuchElementException("Recipient with name: $recipient does not belong exist for school with id: $schoolId")
                    }

            // Get CreditorId
            val creditorId =
                    try {
                        creditorService.getBySchoolIdAndName(schoolId, creditor).id
                    } catch (exception: NoSuchElementException) {
                        throw NoSuchElementException("Creditor with name: $creditor does not belong exist for school with id: $schoolId")
                    }

            // Update
            budgetService.modifyAllFields(budgetId,
                    name,
                    reference,
                    budgetTypeId,
                    recipientId,
                    creditorId,
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
                     recipient: String,
                     creditor: String,
                     comment: String?): Int {
        val budgetTypeId = BudgetTypeService().getBySchoolIdAndName(schoolId, type).id
        val recipientId = RecipientService().getBySchoolIdAndName(schoolId, recipient).id
        val creditorId = CreditorService().getBySchoolIdAndName(schoolId, creditor).id
        return budgetService.createInDb(name, reference, schoolId,
                budgetTypeId, recipientId, creditorId, comment)
                ?: throw RuntimeException("Id of new budget is null after insert statement")
    }

    fun convertToBudgetForIHM(budget: Budget): BudgetForIHM {
        val budgetType = budgetTypeService.getName(budget.typeId)
        val recipient = recipientService.getName(budget.recipientId)
        val creditor = creditorService.getName(budget.creditorId)
        return BudgetForIHM(
                budget.id,
                budget.name,
                budget.reference,
                budget.schoolId,
                budgetType,
                recipient,
                creditor,
                budget.comment,
                budget.realRemaining,
                budget.virtualRemaining,
                budget.operations
                )
    }

    fun getTypes(schoolId: Int): List<GenericBudgetItem> {
        val types = budgetTypeService.getBySchoolId(schoolId)
        if (types.isEmpty()) {
            throw NoSuchElementException("no budget types found for school: $schoolId")
        }
        return types
    }

    fun getRecipients(schoolId: Int): List<GenericBudgetItem> {
        val recipients = recipientService.getBySchoolId(schoolId)
        if (recipients.isEmpty()) {
            throw NoSuchElementException("no budget recipients found for school: $schoolId")
        }
        return recipients
    }

    fun getCreditors(schoolId: Int): List<GenericBudgetItem> {
        val creditors = creditorService.getBySchoolId(schoolId)
        if (creditors.isEmpty()) {
            throw NoSuchElementException("no budget creditors found for school: $schoolId")
        }
        return creditors
    }
}

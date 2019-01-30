import budget.*
import com.fasterxml.jackson.databind.SerializationFeature
import io.ktor.application.*
import io.ktor.auth.*
import io.ktor.content.*
import io.ktor.features.CallLogging
import io.ktor.features.Compression
import io.ktor.features.ContentNegotiation
import io.ktor.features.DefaultHeaders
import io.ktor.http.*
import io.ktor.jackson.jackson
import io.ktor.locations.*
import io.ktor.request.header
import io.ktor.request.receive
import io.ktor.response.*
import io.ktor.routing.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import mu.KotlinLogging.logger
import operation.*
import school.School
import school.SchoolModel
import user.User
import user.UserCache
import user.UserModel
import java.io.File


data class EnvironmentVariables(val home: String, val port: Int, val indexFile: String)
data class JsonHomeResponse(val budgetSummaries: List<BudgetSummary>)
data class JsonLoginResponse(val token: String, val user: User, val school: School)
data class JsonBudgetResponse(val budget: BudgetForIHM)
data class JsonGenericBudgetItemsResponse(val items: List<GenericBudgetItem>)
data class JsonUpdateBudgetDecoder(val id: Int,
                                   val name: String,
                                   val reference: String,
                                   val budgetType: String,
                                   val recipient: String,
                                   val creditor: String,
                                   val comment: String)
data class JsonCreateBudgetDecoder(val name: String,
                                   val reference: String,
                                   val budgetType: String,
                                   val recipient: String,
                                   val creditor: String,
                                   val comment: String)
data class JsonId(val id: Int)



fun main(args: Array<String>) {

    val logger = logger("main")

    val userModel = UserModel()
    val schoolModel = SchoolModel()
    val budgetModel = BudgetModel()
    val operationModel = OperationModel()

    val environment =  System.getenv("SUPERD_ENVIRONMENT") ?: "PRODUCTION"
    if (environment.toLowerCase() == "dev") {
        userModel.userService.flushUsers()
        operationModel.operationService.flush()
        budgetModel.budgetService.flush()
        budgetModel.budgetTypeService.flush()
        budgetModel.recipientService.flush()
        budgetModel.creditorService.flush()
        schoolModel.schoolService.flush()

        schoolModel.schoolService.populate()
        userModel.userService.populateUsers()
        budgetModel.creditorService.populate()
        budgetModel.recipientService.populate()
        budgetModel.budgetTypeService.populate()
        budgetModel.budgetService.populate()
        val budgetId = budgetModel.getFirstBudgetIdBySchoolReference("SiretDuPlessis")
        operationModel.operationService.populate(budgetId)
    }

    val (home, port, indexFile) = get_environment_variables()

    val server = embeddedServer(Netty, port = port) {
        install(DefaultHeaders)
        install(Compression)
        install(CallLogging)
        install(Locations)

        install(ContentNegotiation) {
            jackson {
                enable(SerializationFeature.INDENT_OUTPUT) // Pretty Prints the JSON
            }
        }

        install(Authentication) {

            form(name = "form") {
                userParamName = "email"
                passwordParamName = "password"
                challenge = FormAuthChallenge.Unauthorized
                validate { credentials ->
                    val expectedPassword = userModel.getPasswordFromDb(credentials.name)
                    val hashedPassword = userModel.hash(credentials.password)
                    if (hashedPassword == expectedPassword)
                        UserIdPrincipal(credentials.name)
                    else
                        null
                }
            }
        }

        routing {

            static("static") {
                staticRootFolder = File("$home/frontend")
                files("dist")
                default(indexFile)
            }

            authenticate("form") {
                post("/login") {
                    try {
                        log.debug("POST LOGIN RECEIVED")
                        val principal: UserIdPrincipal? = call.authentication.principal()
                        val email = principal!!.name

                        val user = userModel.getUserFromEmailOrThrow(email)
                        val school = schoolModel.getSchoolFromIdOrThrow(user.schoolId)
                        val token = generate_token(user, school)
                        val jsonResponse = JsonLoginResponse(token, user, school)

                        call.respond(jsonResponse)
                    } catch (e: Exception) {
                        call.respond(HttpStatusCode.Unauthorized)
                    }
                }
            }

            delete("/budget/{id}/operations") {
                log.debug("OPERATION DELETE RECEIVED")
                try {
                    val budget = checkSchoolAndBudgetIds(call, budgetModel)

                    val operationToDelete = call.receive<JsonId>()
                    operationModel.deleteOperation(budget.id, operationToDelete.id)
                    call.respond(HttpStatusCode.OK)
                }
                catch (e: NoSuchElementException) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "the budget does not exist in database")
                }
                catch (e: Exception) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "error while deleting the operation")
                }
            }

            get("/") {
                val html = File("$home/frontend/dist/$indexFile").readText()
                call.respondText(html, ContentType.Text.Html)
            }

            get("/home") {
                log.debug("GET HOME RECEIVED")
                try {
                    val token = call.request.header("token")
                    val (_, schoolId) = UserCache.getSessionData(token!!)

                    val budgetSummaries = budgetModel.getBudgetSummariesFromSchoolId(schoolId)
                    call.respond(JsonHomeResponse(budgetSummaries))

                } catch (e: Exception) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.Unauthorized)
                }
            }

            get("/budget/{id}") {
                log.debug("GET BUDGET RECEIVED")
                try {
                    val budget = checkSchoolAndBudgetIds(call, budgetModel)
                    val jsonBudget = budgetModel.convertToBudgetForIHM(budget)
                    call.respond(JsonBudgetResponse(jsonBudget))
                }
                catch (e: NoSuchElementException) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "the budget does not exist in database")
                }
                catch (e: Exception) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.Unauthorized)
                }
            }

            get("/budget-types") {
                log.debug("GET BUDGET-TYPES RECEIVED")
                try {
                    val schoolId = checkToken(call)
                    val budgetTypes = budgetModel.getTypes(schoolId)
                    call.respond(JsonGenericBudgetItemsResponse(budgetTypes))
                }
                catch (e: NoSuchElementException) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "no budget types in database for this school")
                }
                catch (e: Exception) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.Unauthorized)
                }
            }

            get("/creditors") {
                log.debug("GET CREDITORS RECEIVED")
                try {
                    val schoolId = checkToken(call)
                    val creditors = budgetModel.getCreditors(schoolId)
                    call.respond(JsonGenericBudgetItemsResponse(creditors))
                }
                catch (e: NoSuchElementException) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "no budget creditors in database for this school")
                }
                catch (e: Exception) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.Unauthorized)
                }
            }

            get("/recipients") {
                println("GET RECIPIENTS RECEIVED")
                try {
                    val schoolId = checkToken(call)
                    val recipients = budgetModel.getRecipients(schoolId)
                    call.respond(JsonGenericBudgetItemsResponse(recipients))
                }
                catch (e: NoSuchElementException) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "no budget recipients in database for this school")
                }
                catch (e: Exception) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.Unauthorized)
                }
            }

            post("/budget") {
                log.debug("BUDGET CREATION RECEIVED")
                try {
                    val jsonBudgetToCreate = call.receive<JsonCreateBudgetDecoder>()

                    val schoolId = checkToken(call)

                    val createdId = budgetModel.createBudget(jsonBudgetToCreate.name,
                                                            jsonBudgetToCreate.reference,
                                                            schoolId,
                                                            jsonBudgetToCreate.budgetType,
                                                            jsonBudgetToCreate.recipient,
                                                            jsonBudgetToCreate.creditor,
                                                            jsonBudgetToCreate.comment)
                    call.respond(JsonId(createdId))
                }
                catch (e: Exception) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "error while creating the budget")
                }
            }

            post("/budget/{id}/operations") {
                log.debug("OPERATION CREATION RECEIVED")
                try {
                    val budget = checkSchoolAndBudgetIds(call, budgetModel)

                    val jsonOperationToCreate = call.receive<JsonOperation>()
                    val operationToCreate = jsonOperationToCreate.convertToOperation(budget.id)

                    operationModel.createOperation(budget.id, operationToCreate)
                    call.respond(HttpStatusCode.OK)
                }
                catch (e: NoSuchElementException) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "the budget does not exist in database")
                }
                catch (e: Exception) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "error while creating the operation")
                }
            }

            post("/logout") {
                log.debug("LOGOUT RECEIVED")
                try {
                    val token = call.request.header("token")
                    if (token !== null) {
                        UserCache.removeSessionData(token)
                    }
                    call.respond(HttpStatusCode.NoContent)

                } catch (e: Exception) {
                    call.respond(HttpStatusCode.NoContent)
                }
            }

            put("/budget") {
                log.debug("BUDGET MODIFICATION RECEIVED")
                try {
                    val jsonBudgetToUpdate = call.receive<JsonUpdateBudgetDecoder>()
                    val id = jsonBudgetToUpdate.id

                    val budgetToUpdate = checkSchoolAndBudgetIds(call, budgetModel, id)

                    budgetModel.updateAllFields(budgetToUpdate.schoolId,
                            budgetToUpdate.id,
                            jsonBudgetToUpdate.name,
                            jsonBudgetToUpdate.reference,
                            jsonBudgetToUpdate.budgetType,
                            jsonBudgetToUpdate.recipient,
                            jsonBudgetToUpdate.creditor,
                            jsonBudgetToUpdate.comment)

                    call.respond(HttpStatusCode.OK)
                }
                catch (e: NoSuchElementException) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "the budget does not exist in database")
                }
                catch (e: Exception) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "error while updating the budget")
                }
            }

            put("/budget/{id}/operations") {
                log.debug("OPERATION MODIFICATION RECEIVED")
                try {
                    val budget = checkSchoolAndBudgetIds(call, budgetModel)

                    val jsonOperationToUpdate = call.receive<JsonOperation>()
                    val operationToUpdate = jsonOperationToUpdate.convertToOperation(budget.id)

                    operationModel.updateAllFields(operationToUpdate)
                    call.respond(HttpStatusCode.OK)
                }
                catch (e: NoSuchElementException) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "the budget does not exist in database")
                }
                catch (e: Exception) {
                    logger.error(e.message)
                    call.respond(HttpStatusCode.InternalServerError, "error while updating the operation")
                }
            }

        }
    }
    server.start(wait = true)
}

private fun get_environment_variables(): EnvironmentVariables {
    val environment = System.getenv("SUPERD_ENVIRONMENT") ?: "PRODUCTION"
    var home = "/home/softcybersec/dev/superdirectrice"
    var port = 8080
    var indexFile = "index-dev.html"
    if (environment.toLowerCase() != "dev") {
        home = System.getenv("HOME") ?: throw RuntimeException("HOME environment variable is not defined")
        port = System.getenv("PORT")?.toInt() ?: throw RuntimeException("PORT environment variable is not defined")
        indexFile = "index.html"
    }

    return EnvironmentVariables(home, port, indexFile)
}

private fun generate_token(user: User, school: School): String {
    val sessionId = java.util.UUID.randomUUID().toString()
    UserCache.setSessionId(user.id, school.id, sessionId)
    return sessionId
}

private fun checkSchoolAndBudgetIds(call: ApplicationCall, budgetModel: BudgetModel, budgetId: Int? = null)
        : Budget {

    val schoolId = checkToken(call)
    val id = budgetId ?: call.parameters["id"]?.toInt() ?: throw NoSuchElementException()

    val budget = budgetModel.getBudgetById(id)
    if (budget.schoolId !== schoolId) {
        throw IllegalArgumentException("the budget $budgetId does not belong to school $schoolId")
    }

    return budget
}

private fun checkToken(call: ApplicationCall): Int {
    val token = call.request.header("token")
    val (_, schoolId) = UserCache.getSessionData(token!!)
    return schoolId
}
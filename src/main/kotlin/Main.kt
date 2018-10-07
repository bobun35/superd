import budget.Budget
import budget.BudgetModel
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
import io.ktor.response.*
import io.ktor.routing.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import operation.Operation
import operation.OperationModel
import school.School
import school.SchoolModel
import user.User
import user.UserCache
import user.UserModel
import java.io.File


data class EnvironmentVariables(val home: String, val port: Int, val indexFile: String)
data class JsonHomeResponse(val budgets: List<Budget>)
data class JsonLoginResponse(val token: String, val user: User, val school: School)
data class JsonOperationResponse(val operations: List<Operation>)


fun main(args: Array<String>) {

    val userModel = UserModel()
    val schoolModel = SchoolModel()
    val budgetModel = BudgetModel()
    val operationModel = OperationModel()

    val environment =  System.getenv("SUPERD_ENVIRONMENT") ?: "PRODUCTION"
    if (environment.toLowerCase() == "dev") {
        userModel.userService.flushUsers()
        budgetModel.budgetService.flushBudgets()
        schoolModel.schoolService.flushSchools()

        schoolModel.schoolService.populateSchools()
        userModel.userService.populateUsers()
        budgetModel.budgetService.populateBudgets()
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
            basic(name = "auth") {
                realm = "SuperDirectrice"
                validate { credentials ->
                    val expectedPassword = userModel.getPasswordFromDb(credentials.name)
                    // TODO hash password before comparison
                    if (credentials.password == expectedPassword)
                        UserIdPrincipal(credentials.name)
                    else
                        null
                }
            }
        }

        routing {

            static("frontend") {

                staticRootFolder = File("$home/frontend")
                files("dist")
                default(indexFile)
            }

            get("/") {
                println("REDIRECT TO $indexFile")
                call.respondRedirect("/frontend/$indexFile")
            }

            authenticate("auth") {
                post("/login") {
                    try {
                        println("POST LOGIN RECEIVED")
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

            get("/home") {
                println("GET HOME RECEIVED")
                try {
                    val token = call.request.header("token")
                    val (_, schoolId) = UserCache.getSessionData(token!!)

                    val budgets = budgetModel.getBudgetsFromSchoolId(schoolId)
                    call.respond(JsonHomeResponse(budgets))

                } catch (e: Exception) {
                    call.respond(HttpStatusCode.Unauthorized)
                }
            }

            get("/{id}/operations") {
                println("GET OPERATIONS RECEIVED")
                try {
                    val token = call.request.header("token")
                    val (_, schoolId) = UserCache.getSessionData(token!!)
                    val budgetId = call.parameters["id"]?.toInt() ?: throw NoSuchElementException()

                    val budget = budgetModel.getBudgetById(budgetId)
                    if (budget.schoolId !== schoolId) {
                        call.respond(HttpStatusCode.InternalServerError, "the budget does not belong to your shool")
                    }

                    val operations = operationModel.getAllOperationsFromBudgetId(budgetId)
                    call.respond(JsonOperationResponse(operations))

                }

                catch (e: NoSuchElementException) {
                    call.respond(HttpStatusCode.InternalServerError, "the budget does not exist in database")
                }

                catch (e: Exception) {
                    call.respond(HttpStatusCode.Unauthorized)
                }
            }

            post("/logout") {
                println("LOGOUT RECEIVED")
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


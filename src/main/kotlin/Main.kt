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
import school.SchoolService
import user.User
import user.UserCache
import user.UserService
import java.io.File


data class EnvironmentVariables(val home: String, val port: Int, val indexFile: String)

fun main(args: Array<String>) {

    val userService = UserService()
    val schoolService = SchoolService()

    val environment =  System.getenv("SUPERD_ENVIRONMENT") ?: "PRODUCTION"
    if (environment.toLowerCase() == "dev") {
        schoolService.populateSchools()
        userService.populateUsers()
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
                    val expectedPassword = userService.getPasswordFromDb(credentials.name)
                    if (expectedPassword != null && credentials.password == expectedPassword)
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
                    println("POST LOGIN RECEIVED")
                    val principal: UserIdPrincipal? = call.authentication.principal()
                    if (principal != null) {
                        val sessionId = java.util.UUID.randomUUID().toString()
                        UserCache.setSessionId(principal.name, sessionId)
                        call.respond(TextContent("{\"token\": \"$sessionId\"}", ContentType.Application.Json))
                        call.respond(HttpStatusCode.OK)
                    } else {
                        call.respond(HttpStatusCode.Unauthorized)
                    }
                }
            }

            get("/home") {
                println("GET HOME RECEIVED")
                val token = call.request.header("token")
                val email = UserCache.getEmail(token)
                if (email == null || token == null)
                    call.respond(HttpStatusCode.Unauthorized)
                else {
                    val user: User? = userService.getUser(email)
                    if (user == null)
                        call.respond(HttpStatusCode.InternalServerError)
                    else
                        call.respond(HttpStatusCode.OK,
                                    TextContent("{\"budget\": \"ecole Plessis\"}",
                                         ContentType.Application.Json))
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


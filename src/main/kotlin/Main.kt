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
import user.UserCache
import user.UserService
import java.io.File


data class UserSession(val email: String)

fun main(args: Array<String>) {

    // TODO remove this for production, used here to populate users database
    val userService = UserService()

    val server = embeddedServer(Netty, port = 443) {
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
                staticRootFolder = File("/home/softcybersec/dev/superdirectrice/frontend")
                files("dist")
                default("index.html")
            }

            get("/") {
                call.respondRedirect("/frontend/index.html", permanent = true)
            }

            authenticate("auth") {
                post("/login") {
                    val principal: UserIdPrincipal? = call.authentication.principal()
                    if (principal != null) {
                        val sessionId = java.util.UUID.randomUUID().toString()
                        UserCache.setSessionId(principal.name, sessionId)
                        call.response.header("UserSession", sessionId)
                        call.respond(HttpStatusCode.OK)
                    } else {
                        call.respond(HttpStatusCode.Unauthorized)
                    }
                }
            }

            get("/home") {
                val currentUserSession = call.request.header("UserSession")
                if (currentUserSession != null) {
                    val userEmail = UserCache.getEmail(currentUserSession)
                    if (userEmail != null) {
                        val userSession = UserSession(userEmail)
                        call.respond(userSession)
                    }
                }
                    else {
                    call.respond(HttpStatusCode.Unauthorized)
                }
            }
        }
    }
    server.start(wait = true)
}

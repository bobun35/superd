import com.fasterxml.jackson.databind.SerializationFeature
import common.Cache
import common.RedisCache.Companion.logger
import io.ktor.application.*
import io.ktor.auth.*
import io.ktor.content.*
import io.ktor.features.ContentNegotiation
import io.ktor.http.*
import io.ktor.jackson.jackson
import io.ktor.locations.*
import io.ktor.request.receive
import io.ktor.response.*
import io.ktor.routing.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import io.ktor.sessions.*
import io.ktor.util.hex
import io.ktor.util.nonceRandom
import user.UserService
import java.io.File
import java.security.MessageDigest


@Location("/login")
data class AuthenticationData(val email: String, val password: String)

data class UserSession(val name: String, val value: Int)

fun main(args: Array<String>) {

    UserService()

    val server = embeddedServer(Netty, port = 8080) {
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
                    val userService = UserService()
                    val expectedPassword = userService.getPasswordFromDb(credentials.name)
                    if (expectedPassword !== null && credentials.password == expectedPassword) UserIdPrincipal(credentials.name) else null
                }
            }
        }

        install(Sessions) {
            header<UserSession>("UserSession", Cache) { // install a header server-side session
                identity { java.util.UUID.randomUUID().toString() }
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
                    call.sessions.set(UserSession(name = "John", value = 12))
                    logger.info("CLAIRE" + call.sessions.get<UserSession>().toString())
                    call.respond(HttpStatusCode.OK)
                }
            }
        }
    }
    server.start(wait = true)
}

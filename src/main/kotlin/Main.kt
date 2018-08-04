import com.fasterxml.jackson.databind.SerializationFeature
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
import io.ktor.util.hex
import user.UserService
import java.io.File
import java.security.MessageDigest


@Location("/login")
data class AuthenticationData(val email: String, val password: String)


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
                realm = "MyRealm"
                validate { credentials ->
                    val userService = UserService()
                    val expectedPassword = userService.getPasswordFromDb(credentials.name)
                    if (expectedPassword !== null && credentials.password == expectedPassword) UserIdPrincipal(credentials.name) else null
                }
            }
        }

        /* install(Authentication) {
            val usersInMyRealmToSHA256: Map<String, ByteArray> = mapOf(
                    // pass="test", HA1=MD5("test:MyRealm:pass")="fb12475e62dedc5c2744d98eb73b8877"
                    // echo -n test:MyRealm:pass | md5sum
                    "test" to hex("fb12475e62dedc5c2744d98eb73b8877")
            )

            digest("auth") {
                realm = "MyRealm"
                userNameRealmPasswordDigestProvider = { userName, _ ->
                    usersInMyRealmToSHA256[userName]
                }
            }
        }*/

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
                    val authenticationData = call.receive<AuthenticationData>()
                    call.respond(HttpStatusCode.OK)
                }
            }
        }
    }
    server.start(wait = true)
}

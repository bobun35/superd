import io.ktor.application.*
import io.ktor.content.*
import io.ktor.http.*
import io.ktor.locations.*
import io.ktor.response.*
import io.ktor.routing.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import java.io.File


@Location("/login")
data class AuthenticationData(val login: String, val password: String)


fun main(args: Array<String>) {
    val server = embeddedServer(Netty, port = 8080) {
        install(Locations)

        routing {

            static("frontend") {
                staticRootFolder = File("/home/softcybersec/dev/superdirectrice/frontend")
                files("dist")
                default("index.html")
            }

            get("/") {
                call.respondRedirect("/frontend/index.html", permanent = true)
            }

            get<AuthenticationData> { authenticationData ->
                call.respondText("Received: ${authenticationData.login} and ${authenticationData.password}")
            }
        }
    }
    server.start(wait = true)
}

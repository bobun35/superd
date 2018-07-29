import com.fasterxml.jackson.databind.SerializationFeature
import io.ktor.application.*
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
import java.io.File


@Location("/login")
data class AuthenticationData(val email: String, val password: String)


fun main(args: Array<String>) {
    val server = embeddedServer(Netty, port = 8080) {
        install(Locations)
        install(ContentNegotiation) {
            jackson {
                enable(SerializationFeature.INDENT_OUTPUT) // Pretty Prints the JSON
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

            post("/login") {
                val authenticationData = call.receive<AuthenticationData>()
                call.respond(HttpStatusCode.OK)
            }
        }
    }
    server.start(wait = true)
}

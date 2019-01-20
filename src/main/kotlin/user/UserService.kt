package user

import com.fasterxml.jackson.annotation.JsonIgnore
import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import school.School
import school.SchoolService
import java.security.MessageDigest


const val USER_TABLE_NAME = "users"

data class User(val id: Int,
                val email: String,
                @JsonIgnore
                val password: String,
                val firstName: String,
                val lastName: String,
                @JsonIgnore
                val schoolId: Int)

class UserService {

    val schoolService = SchoolService()
    val salt = System.getenv("SALT")?.toString() ?: "jgush79khdg84#@67Ufas3!*sfe-svvil"

    object table {
        // object name and database table name shall be the same
        object users : Table() {
            val id = integer("id").autoIncrement().primaryKey()
            val email = varchar("email", 100)
            val password = varchar("password", 100)
            val firstName = varchar("first_name", 100)
            val lastName = varchar("last_name", 100)

            // TODO allow several schools per user
            val schoolId = (integer("school_id") references SchoolService.table.schools.id)
        }
    }

    companion object: KLoggable {
        override val logger = logger()
    }

    init {
        SqlDb.connect()
        SqlDb.ensureTableExists(table.users)
    }

    fun flushUsers() {
        SqlDb.flush(table.users)
    }

    fun populateUsers() {
        createUserInDb("claire@superd.net", "pass123",
                "claire",  "Example", "SiretDuPlessis")
    }

    fun getPasswordFromDb(email: String): String? {
        return getUserByEmail(email)?.password
    }

    fun createUserInDb(userEmail: String, userPassword: String, firstName: String,
                       lastName: String, userSchool: String) {
        try {

            val school: School? = schoolService.getByReference(userSchool)
            if (school == null) {
                logger.error("school with reference: $userSchool does not exists in database")
                throw Exception("school with reference: $userSchool does not exists in database")
            }

            transaction {
                table.users.insert { it[table.users.email] = userEmail
                                     it[table.users.password] = hash(userPassword)
                                     it[table.users.firstName] = firstName
                                     it[table.users.lastName] = lastName
                                     it[table.users.schoolId] = school!!.id
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
    }

    fun hash(password: String): String {
        val salted = this.salt + password
        val bytes = salted.toByteArray()
        val md = MessageDigest.getInstance("SHA-256")
        val digest = md.digest(bytes)
        return digest.fold("") { str, it -> str + "%02x".format(it) }
    }

    fun getUserByEmail(email: String): User? {
        return getUser { table.users.email eq email }
    }

    private fun getUser(where: SqlExpressionBuilder.()-> Op<Boolean>): User? {
        var user: User? = null
        try {
            transaction {
                val result = table.users.select( where )

                if (result.count() == 1) {
                    for (row in result) {
                        user = User(
                                row[table.users.id],
                                row[table.users.email],
                                row[table.users.password],
                                row[table.users.firstName],
                                row[table.users.lastName],
                                row[table.users.schoolId])
                    }
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
        return user
    }
}

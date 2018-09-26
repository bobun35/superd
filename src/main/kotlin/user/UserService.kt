package user

import com.fasterxml.jackson.annotation.JsonIgnore
import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import school.School
import school.SchoolService


const val USER_TABLE_NAME = "users"

data class User(val id: Int,
                val email: String,
                @JsonIgnore
                val password: String,
                @JsonIgnore
                val schoolId: Int)

class UserService {

    val schoolService = SchoolService()

    object table {
        // object name and database table name shall be the same
        object users : Table() {
            val id = integer("id").autoIncrement().primaryKey()
            val email = varchar("email", 100)
            val password = varchar("password", 100)

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

    fun populateUsers() {
        SqlDb.flush(table.users)
        createUserInDb("claire@superd.net", "pass123", "plessis")
    }

    fun getPasswordFromDb(email: String): String? {
        return getUserByEmail(email)?.password
    }

    // TODO hash password before storing
    fun createUserInDb(userEmail: String, userPassword: String, userSchool: String) {
        try {

            val school: School? = schoolService.getSchoolBySiret(userSchool)

            transaction {
                table.users.insert { it[table.users.email] = userEmail
                                     it[table.users.password] = userPassword
                                     it[table.users.schoolId] = school!!.id
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
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

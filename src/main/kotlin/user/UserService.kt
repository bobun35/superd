package user

import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.*
import org.jetbrains.exposed.sql.transactions.transaction
import school.School
import school.SchoolService


const val USER_TABLE_NAME = "users"

data class User(val userId: Int, val email: String, val password: String, val schoolId: Int)

class UserService {

    val schoolService = SchoolService()

    object table {
        // object name and database table name shall be the same
        object users : Table() {
            val userId = integer("id").autoIncrement().primaryKey()
            val userEmail = varchar("user_email", 100)
            val userPassword = varchar("user_password", 100)
            val schoolId = (integer("school_id") references SchoolService.table.schools.schoolId)
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

            val school: School? = schoolService.getSchoolByName(userSchool)

            transaction {
                table.users.insert { it[table.users.userEmail] = userEmail
                                     it[table.users.userPassword] = userPassword
                                     it[table.users.schoolId] = school!!.schoolId
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
    }

    inline fun <T:Any, R> whenNotNull(input: T?, callback: (T)->R): R? {
        return input?.let(callback)
    }

    fun getUserById(userId: Int): User? {
        return getUser { table.users.userId eq userId }
    }

    fun getUserByEmail(email: String): User? {
        return getUser { table.users.userEmail eq email }
    }

    private fun getUser(where: SqlExpressionBuilder.()-> Op<Boolean>): User? {
        var user: User? = null
        try {
            transaction {
                val result = table.users.select( where )

                if (result.count() == 1) {
                    for (row in result) {
                        user = User(
                                row[table.users.userId],
                                row[table.users.userEmail],
                                row[table.users.userPassword],
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

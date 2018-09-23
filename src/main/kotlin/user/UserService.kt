package user

import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.select
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
        return getUser(email)?.password
    }

    fun createUserInDb(userEmail: String, userPassword: String, userSchool: String) {
        try {

            val school: School? = schoolService.getSchool(userSchool)

            // TODO reject if school is null
            school?.let {
                transaction {
                    table.users.insert {
                        it[table.users.userEmail] = userEmail
                        it[table.users.userPassword] = userPassword
                        it[table.users.schoolId] = school.schoolId
                    }
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
    }

    inline fun <T:Any, R> whenNotNull(input: T?, callback: (T)->R): R? {
        return input?.let(callback)
    }

    fun getUser(userEmail: String): User? {
        var user: User? = null
        try {
            transaction {
                val result = table.users.select( { table.users.userEmail eq userEmail } )

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

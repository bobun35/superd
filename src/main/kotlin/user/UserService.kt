package user

import common.SqlDb
import mu.KLoggable
import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.insert
import org.jetbrains.exposed.sql.select
import org.jetbrains.exposed.sql.transactions.transaction


const val USER_TABLE_NAME = "users"

class UserService {

    object table {
        // object name and database table name shall be the same
        object users : Table() {
            val user_email = varchar("user_email", 100).primaryKey()
            val user_password = varchar("user_password", 100)
        }
    }

    companion object: KLoggable {
        override val logger = logger()
    }

    init {
        SqlDb.connect()
        SqlDb.ensureTableExists(table.users)
        createUserInDb("claire@superd.net", "pass")
    }

    fun getPasswordFromDb(userEmail: String): String? {
        var userPassword: String? = null
        try {
            transaction {
                val result = table.users.select( { table.users.user_email eq userEmail } )

                if (result.count() == 1) {
                    for (row in result) {
                        userPassword = row[table.users.user_password]
                    }
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
        return userPassword
    }

    fun createUserInDb(userEmail: String, userPassword: String) {
        try {
            transaction {
                table.users.insert {
                    it[table.users.user_email] = userEmail
                    it[table.users.user_password] = userPassword
                }
            }
        } catch (exception: Exception) {
            logger.error("Database error: " + exception.message)
        }
    }
}

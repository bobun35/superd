package common

import mu.KLoggable
import org.jetbrains.exposed.sql.Database
import org.jetbrains.exposed.sql.SchemaUtils
import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.transactions.transaction

class SqlDb {

    companion object: KLoggable {

        override val logger = SqlDb.logger()

        private var connection: Database? = null

        val DB_URL: String
        val DB_USER: String
        val DB_PASSWORD: String

        init {
            val DB_HOSTNAME = "localhost"
            val DB_PORT = "5432"
            val DB_NAME = "superd"

            DB_URL = "jdbc:postgresql://$DB_HOSTNAME:$DB_PORT/$DB_NAME?useSSL=false"
            DB_USER = "superd"
            DB_PASSWORD = "superd"
        }

        fun connect() {
            if (!isConnected()) {
                try {
                    connection = Database.Companion.connect( DB_URL,
                            driver = "org.postgresql.Driver",
                            user = DB_USER,
                            password = DB_PASSWORD)
                } catch (exception: Exception) {
                    logger.error("Database error: " + exception.message)
                }
            }
        }

        fun isConnected(): Boolean {
            try {
                return connection!!.url is String
            } catch (exception: Exception) {
                return false
            }
        }

        fun ensureTableExists(table: Table) {
            try {
                transaction { SchemaUtils.create(table) }
            } catch (exception: Exception) {
                logger.error("Database error: " + exception.message)
            }
        }
    }
}

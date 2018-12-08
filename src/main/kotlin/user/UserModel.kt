package user

import mu.KLoggable
import javax.management.BadAttributeValueExpException

class UserModel {

    val userService = UserService()

    companion object : KLoggable {
        override val logger = logger()
    }

    fun getUserFromEmailOrThrow(email: String): User {
        val user = userService.getUserByEmail(email)
        if (user != null)
            return user
        else {
            logger.error("No user found for email: ${email}")
            throw BadAttributeValueExpException("user does not exists in database")
        }
    }

    fun getPasswordFromDb(email: String): String {
        val password = userService.getPasswordFromDb(email)
        if (password != null)
            return password
        else {
            logger.error("No password found for user email: ${email}")
            throw BadAttributeValueExpException("user does not exists in database")
        }
    }

    fun hash(input: String): String {
        return userService.hash(input)
    }

}
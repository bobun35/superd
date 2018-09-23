package user

import io.kotlintest.shouldBe
import io.kotlintest.specs.StringSpec
import prepareDatabase
import DatabaseListener
import populateDbWithUsers

class UserServiceTest : StringSpec() {
    private val userService = UserService()

    override fun listeners() = listOf(DatabaseListener)

    init {
        "user service should return password" {
            populateDbWithUsers()

            val password = userService.getPasswordFromDb(TEST_EMAIL)
            password shouldBe TEST_PASSWORD
        }

    }

}
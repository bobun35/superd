package user

import io.kotlintest.shouldBe
import io.kotlintest.specs.StringSpec
import prepareDatabase


class UserServiceTest : StringSpec() {
    private val userService = UserService()

    init {
        "user service should return password" {
            prepareDatabase {  }
            userService.createUserInDb(TEST_EMAIL, TEST_PASSWORD)

            val password = userService.getPasswordFromDb(TEST_EMAIL)
            password shouldBe TEST_PASSWORD
        }

    }

}
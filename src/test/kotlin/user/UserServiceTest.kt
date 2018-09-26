package user

import io.kotlintest.shouldBe
import io.kotlintest.specs.StringSpec
import DatabaseListener
import TEST_EMAIL
import TEST_PASSWORD
import TEST_SCHOOL
import io.kotlintest.matchers.boolean.shouldBeTrue
import populateDbWithSchools
import populateDbWithUsers

class UserServiceTest : StringSpec() {
    private val userService = UserService()

    override fun listeners() = listOf(DatabaseListener)

    init {

        "user creation and get should succeed" {
            populateDbWithSchools()
            userService.createUserInDb(TEST_EMAIL, TEST_PASSWORD, TEST_SCHOOL)

            val expectedUser = User(0, TEST_EMAIL, TEST_PASSWORD, 0)
            val actualUser = userService.getUserByEmail(TEST_EMAIL)
            usersAreEqual(actualUser, expectedUser).shouldBeTrue()

        }

        "user service should return password" {
            populateDbWithUsers()

            val password = userService.getPasswordFromDb(TEST_EMAIL)
            password shouldBe TEST_PASSWORD
        }
    }

}

fun usersAreEqual(user1: User?, user2: User?): Boolean {
    return user1?.email == user2?.email && user2?.password == user2?.password
}
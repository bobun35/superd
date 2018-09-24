package school

import io.kotlintest.specs.StringSpec
import DatabaseListener
import TEST_SCHOOL
import io.kotlintest.matchers.boolean.shouldBeTrue
import io.kotlintest.shouldBe


class SchoolServiceTest : StringSpec() {
    private val schoolService = SchoolService()

    override fun listeners() = listOf(DatabaseListener)

    init {

        "school creation and get should succeed" {
            schoolService.createSchoolInDb(TEST_SCHOOL)

            val expectedSchool = School(0, TEST_SCHOOL)
            val actualSchool = schoolService.getSchoolBySiret(TEST_SCHOOL)
            schoolsAreEqual(actualSchool, expectedSchool).shouldBeTrue()

            val actualId = actualSchool!!.id
            val actualUserById = schoolService.getSchoolById(actualId)
            actualUserById.shouldBe(actualSchool)
        }
    }

}

fun schoolsAreEqual(school1: School?, school2: School?): Boolean {
    return school1?.siret == school2?.siret
}
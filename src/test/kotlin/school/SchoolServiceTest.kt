package school

import io.kotlintest.specs.StringSpec
import DatabaseListener
import TEST_SCHOOL_REFERENCE
import TEST_SCHOOL_NAME
import io.kotlintest.matchers.boolean.shouldBeTrue
import io.kotlintest.shouldBe


class SchoolServiceTest : StringSpec() {
    private val schoolService = SchoolService()

    override fun listeners() = listOf(DatabaseListener)

    init {

        "school creation and get should succeed" {
            schoolService.createSchoolInDb(TEST_SCHOOL_REFERENCE, TEST_SCHOOL_NAME)

            val expectedSchool = School(0, TEST_SCHOOL_REFERENCE, TEST_SCHOOL_NAME)
            val actualSchool = schoolService.getSchoolByReference(TEST_SCHOOL_REFERENCE)
            schoolsAreEqual(actualSchool, expectedSchool).shouldBeTrue()

            val actualId = actualSchool!!.id
            val actualUserById = schoolService.getSchoolById(actualId)
            actualUserById.shouldBe(actualSchool)
        }
    }

}

fun schoolsAreEqual(school1: School?, school2: School?): Boolean {
    return school1?.reference == school2?.reference
           && school1?.name == school2?.name
}
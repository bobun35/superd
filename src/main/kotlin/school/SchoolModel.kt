package school

import mu.KLoggable
import javax.management.BadAttributeValueExpException

class SchoolModel {

    val schoolService = SchoolService()

    companion object : KLoggable {
        override val logger = logger()
    }

    fun getSchoolFromIdOrThrow(id: Int): School {
        val school = schoolService.getSchoolById(id)
        if (school != null)
            return school
        else {
            logger.error("No school found for schoolId: ${id}")
            throw BadAttributeValueExpException("school does not exists in database")
        }
    }
}
package user

import TEST_SESSIONID
import common.Cache
import io.kotlintest.Description
import io.kotlintest.extensions.TestListener
import io.kotlintest.shouldBe
import io.kotlintest.specs.StringSpec

class UserCacheTest : TestListener, StringSpec() {

    init {
        "UserCache should set and get session id from cache" {
            val testUserId = 677
            val testSchoolId = 53
            UserCache.setSessionId(testUserId, testSchoolId, TEST_SESSIONID)

            val result = UserCache.getUserId(TEST_SESSIONID)
            result shouldBe testUserId

            val (actualUserId, actualSchoolId) = UserCache.getSessionData(TEST_SESSIONID)
            actualUserId shouldBe testUserId
            actualSchoolId shouldBe testSchoolId

            /*val key = UserCache.getUserSessionKey(TEST_SESSIONID)
            val actualExpireValue = Cache.redisCommand?.ttl(key)
            actualExpireValue shouldBe SESSION_TIMEOUT*/
        }
    }

    override fun beforeTest(description: Description): Unit {
        Cache.flush()
    }
}
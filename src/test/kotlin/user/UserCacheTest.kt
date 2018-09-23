package user

import TEST_EMAIL
import TEST_SESSIONID
import common.Cache
import io.kotlintest.Description
import io.kotlintest.extensions.TestListener
import io.kotlintest.shouldBe
import io.kotlintest.specs.StringSpec

class UserCacheTest : TestListener, StringSpec() {

    init {
        "UserCache should set and get session id from cache" {
            val test_user_id = 677
            UserCache.setSessionId(test_user_id, TEST_SESSIONID)

            val result = UserCache.getUserId(TEST_SESSIONID)
            result shouldBe test_user_id

            val key = UserCache.getUserSessionKey(TEST_SESSIONID)
            val actualExpireValue = Cache.redisCommand?.ttl(key)
            actualExpireValue shouldBe SESSION_TIMEOUT
        }
    }

    override fun beforeTest(description: Description): Unit {
        Cache.flush()
    }
}
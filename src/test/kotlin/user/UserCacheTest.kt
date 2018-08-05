package user

import common.Cache
import io.kotlintest.Description
import io.kotlintest.extensions.TestListener
import io.kotlintest.shouldBe
import io.kotlintest.specs.StringSpec

class UserCacheTest : TestListener, StringSpec() {

    init {
        "UserCache should set and get session id from cache" {
            UserCache.setSessionId(TEST_EMAIL, TEST_SESSIONID)

            val result = UserCache.getEmail(TEST_SESSIONID)
            result shouldBe TEST_EMAIL

            val key = UserCache.getUserSessionKey(TEST_SESSIONID)
            val actualExpireValue = Cache.redisCommand?.ttl(key)
            actualExpireValue shouldBe SESSION_TIMEOUT
        }
    }

    override fun beforeTest(description: Description): Unit {
        Cache.flush()
    }
}
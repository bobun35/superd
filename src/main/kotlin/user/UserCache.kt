package user

import common.Cache
import common.RedisCache
import java.rmi.ServerException

/**
 * Object used to retrieve user temporary information from redis cache
 **/

const val SESSION_TIMEOUT = 3600L

object UserCache {

    fun setSessionId(email: String, sessionId: String) {
        val key = getUserSessionKey(email)
        try {
            Cache.redisCommand?.set(key, sessionId)  ?: throw ServerException("no cache connection available")
            setSessionDuration(key)
        } catch (exception: Exception) {
            val errorMessage = "Redis error while setting (key, value): $key, $sessionId \nException: $exception"
            RedisCache.logger.error(errorMessage)
        }
    }

    internal fun getUserSessionKey(email: String): String {
        return "user:$email:sessionid"
    }

    private fun setSessionDuration(redisSessionKey: String) {
        if (Cache.isConnected()) {
            Cache.redisCommand?.expire(redisSessionKey, SESSION_TIMEOUT)
        }
    }

    fun getSessionId(email: String) : String? {
        val key = getUserSessionKey(email)
        try {
            if (Cache.redisCommand == null) throw ServerException("no cache connection available")
            return Cache.redisCommand?.get(key)
        } catch (exception: Exception) {
            val errorMessage = "Redis error while getting (key): $key \n" +
                    "Exception: $exception"
            RedisCache.logger.error(errorMessage)
            throw exception
        }
    }
}
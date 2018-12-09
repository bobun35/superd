package user

import common.Cache
import common.RedisCache
import java.rmi.ServerException

/**
 * Object used to retrieve user temporary information from redis cache
 **/

const val SESSION_TIMEOUT = 900L

object UserCache {

    fun setSessionId(userId: Int, schoolId: Int, sessionId: String) {
        val key = getUserSessionKey(sessionId)
        try {
            val userSessionData = userId.toString() + ":" + schoolId.toString()
            Cache.redisCommand?.set(key, userSessionData)  ?: throw ServerException("no cache connection available")
            updateSessionDuration(key)
        } catch (exception: Exception) {
            val errorMessage = "Redis error while setting (key, id value): $key, $userId \nException: $exception"
            RedisCache.logger.error(errorMessage)
        }
    }

    internal fun getUserSessionKey(sessionId: String): String {
        return "session_$sessionId"
    }

    private fun updateSessionDuration(redisSessionKey: String) {
        if (Cache.isConnected()) {
            Cache.redisCommand?.expire(redisSessionKey, SESSION_TIMEOUT)
        }
    }

    fun getSessionData(sessionId: String): Pair<Int, Int> {

        val key = getUserSessionKey(sessionId)
        try {
            if (Cache.redisCommand == null) throw ServerException("no cache connection available")
            val userSessionData = Cache.redisCommand?.get(key) ?: throw ServerException("user session not found in cache")

            updateSessionDuration(key)

            val (userId: String, schoolId: String) = userSessionData.split(":")
            return Pair(userId.toInt(), schoolId.toInt())

        } catch (exception: Exception) {
            val errorMessage = "Redis error while getting (key): $key \n" +
                               "Exception: $exception"
            RedisCache.logger.error(errorMessage)
            throw exception
        }
    }

    fun getUserId(sessionId: String) : Int {
        val (userId, _) = getSessionData(sessionId)
        return userId
    }

    fun removeSessionData(sessionId: String) {
        val key = getUserSessionKey(sessionId)
        try {
            if (Cache.redisCommand == null) throw ServerException("no cache connection available")
            Cache.redisCommand?.del(key)
            return
        } catch (exception: Exception) {
            val errorMessage = "Redis error while removing (key): $key \n" +
                    "Exception: $exception"
            RedisCache.logger.error(errorMessage)
            throw exception
        }
    }

}
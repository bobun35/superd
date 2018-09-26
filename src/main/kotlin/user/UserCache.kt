package user

import common.Cache
import common.RedisCache
import java.rmi.ServerException

/**
 * Object used to retrieve user temporary information from redis cache
 **/

const val SESSION_TIMEOUT = 3600L

object UserCache {

    var userCache = mutableMapOf<String, String>()

    fun setSessionId(userId: Int, schoolId: Int, sessionId: String) {
        val key = getUserSessionKey(sessionId)
        try {
            userCache[key] = userId.toString() + ":" + schoolId.toString()
            //Cache.redisCommand?.set(key, email)  ?: throw ServerException("no cache connection available")
            //setSessionDuration(key)
        } catch (exception: Exception) {
            val errorMessage = "Redis error while setting (key, id value): $key, $userId \nException: $exception"
            RedisCache.logger.error(errorMessage)
        }
    }

    internal fun getUserSessionKey(sessionId: String): String {
        return "session_$sessionId"
    }

    //private fun setSessionDuration(redisSessionKey: String) {
    //    if (Cache.isConnected()) {
    //        Cache.redisCommand?.expire(redisSessionKey, SESSION_TIMEOUT)
    //    }
    //}

    fun getSessionData(sessionId: String): Pair<Int, Int> {

        val key = getUserSessionKey(sessionId)
        try {
            //if (Cache.redisCommand == null) throw ServerException("no cache connection available")
            //return Cache.redisCommand?.get(key)
            val (userId: String, schoolId: String) = userCache[key]!!.split(":")
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

}
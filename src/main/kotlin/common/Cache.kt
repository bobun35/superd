package common

import com.lambdaworks.redis.RedisClient
import com.lambdaworks.redis.api.sync.RedisCommands
import mu.KLoggable
import user.SESSION_TIMEOUT
import java.util.concurrent.TimeUnit

/**
 * RedisCache manages access to redis database
 * Cache is a singleton used to access the RedisCache
 **/

object Cache : RedisCache()

open class RedisCache : SimplifiedSessionStorage() {

    companion object: KLoggable {
        override val logger = logger()
    }

    val CACHE_HOSTNAME = "localhost"
    val CACHE_PORT = "6379"
    val CACHE_PASSWORD = "superd"

    var redisCommand : RedisCommands<String, String>? = null

    init {
        try {
            val redisClient = RedisClient.create("redis://$CACHE_HOSTNAME:$CACHE_PORT/0")
            createSynchronousRedisCommands(redisClient)
        } catch (exception: Exception) {
            val errorMessage = "Redis connection error for host: $CACHE_HOSTNAME \n Exception: $exception"
            logger.error(errorMessage)
        }
    }

    /** configure connection to redis cache */
    private fun createSynchronousRedisCommands(redisClient: RedisClient) {
        val redisConnection = redisClient.connect()
        redisCommand = redisConnection.sync()
        redisCommand?.setTimeout(10L, TimeUnit.SECONDS)
        redisCommand?.auth(CACHE_PASSWORD)
    }

    /** check if connection to redis cache is available */
    fun isConnected(): Boolean {
        if (redisCommand == null) {
            val errorMessage = "no connection available with the cache"
            RedisCache.logger.error(errorMessage)
            return false
        }
        return true
    }

    /** flush the redis cache */
    fun flush() {
        if (isConnected()) {
            try {
                redisCommand?.flushdb()
            } catch (exception: Exception) {
                val errorMessage = "Redis connection error for host: $CACHE_HOSTNAME \n Exception: $exception"
                logger.error(errorMessage)
            }
        }
    }

    private fun buildKey(id: String) = "session_$id"

    override suspend fun read(id: String): ByteArray? {
        val key = buildKey(id)
        val result = redisCommand?.get(key)?.toByteArray()
        if (result != null) {
            redisCommand?.expire(key, SESSION_TIMEOUT) // refresh
        }
        return result
    }

    override suspend fun write(id: String, data: ByteArray?) {
        val key = buildKey(id)
        if (data == null) {
            logger.info("set in redis, data is null: $key")
            redisCommand?.del(buildKey(id))
        } else {
            logger.info("set in redis: $key")
            redisCommand?.set(key, data.toString())
            redisCommand?.expire(key, SESSION_TIMEOUT)
        }
    }

}
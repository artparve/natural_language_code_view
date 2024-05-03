package cub.async.answers

import cub.async.tasks.Server
import cub.async.tasks.posts
import kotlinx.coroutines.*
import java.lang.Runnable
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine
import kotlin.system.measureTimeMillis

fun getWorkers(): ExecutorService {
    val cores = Runtime.getRuntime().availableProcessors()
    println("#cores: $cores")
    return Executors.newFixedThreadPool(cores * 8)
}

fun solutionUsingAsync() {
    val myAsync = MyAsyncFramework()
    for (text in posts) {
        myAsync.async({ Server.getToken() }) { token ->
            Server.submitPost(text, token)
        }
    }
    Thread.sleep(500) // ;^)
    myAsync.close()
}

fun threadsSolution() {
    val threadPool = getWorkers()

    for (text in posts) {
        val runnable = Runnable {
            val token = Server.getToken()
            val meta = Server.submitPost(text, token)
        }
        threadPool.execute(runnable)
    }

    threadPool.shutdown()
    threadPool.awaitTermination(1, TimeUnit.HOURS)
    println("All posts processed")
}

suspend fun submitPostNicely(text: String, token: Server.Token) =
    withContext(Dispatchers.IO) {
        Server.submitPost(text, token)
    }

fun coroutinesSolution() {
    runBlocking {
        coroutineScope {
            for (text in posts) {
                launch(Dispatchers.IO) {
                    val token = suspendCoroutine { it.resume(Server.getToken()) }
                    val meta = submitPostNicely(text, token)
                    // val meta = suspendCoroutine { it.resume(Server.submitPost(text, token)) }
                }
            }
        }
    }
    println("All posts processed")
}

fun main() {
    val timeThreads = measureTimeMillis {
        threadsSolution()
    }
    println("It took ${timeThreads.toDouble() / posts.size} on average")
    val timeCoroutines = measureTimeMillis {
        coroutinesSolution()
    }
    println("It took ${timeCoroutines.toDouble() / posts.size} on average")
    val timeAsync = measureTimeMillis {
        solutionUsingAsync()
    }
    println("It took ${timeAsync.toDouble() / posts.size} on average")
}
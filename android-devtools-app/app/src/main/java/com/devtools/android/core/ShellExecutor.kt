package com.devtools.android.core

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Executes shell commands, optionally using `su` for root commands.
 *
 * - [execCollect] runs a command and collects the full output as a [ShellResult].
 * - [exec] streams stdout lines as a [Flow], cancelling the process on flow cancellation.
 */
object ShellExecutor {

    /**
     * Executes [cmd] synchronously and returns a [ShellResult].
     *
     * If [root] is true and the device is not rooted, returns [ShellResult.RootRequired].
     * Exit code 127 (command not found) returns [ShellResult.BinaryMissing].
     */
    suspend fun execCollect(cmd: String, root: Boolean = false): ShellResult {
        if (root && !RootDetector.isRooted) {
            return ShellResult.RootRequired
        }

        val command = if (root) {
            arrayOf("su", "-c", cmd)
        } else {
            arrayOf("sh", "-c", cmd)
        }

        return try {
            val process = Runtime.getRuntime().exec(command)
            val stdout = process.inputStream.bufferedReader().readText()
            val stderr = process.errorStream.bufferedReader().readText()
            val exitCode = process.waitFor()

            when {
                exitCode == 0 -> ShellResult.Success(stdout.trimEnd())
                exitCode == 127 -> {
                    // 127 = command not found; extract the binary name from stderr or cmd
                    val binaryName = cmd.trim().split(" ").firstOrNull() ?: cmd
                    ShellResult.BinaryMissing(binaryName)
                }
                else -> ShellResult.Failed(stderr = stderr.trimEnd(), exitCode = exitCode)
            }
        } catch (e: Exception) {
            ShellResult.Failed(stderr = e.message ?: "Unknown error", exitCode = -1)
        }
    }

    /**
     * Executes [cmd] and emits stdout lines as they arrive via a [Flow].
     * The underlying [Process] is destroyed when the flow is cancelled.
     */
    fun exec(cmd: String, root: Boolean = false): Flow<String> = callbackFlow {
        if (root && !RootDetector.isRooted) {
            close(IllegalStateException("Root access required but device is not rooted"))
            return@callbackFlow
        }

        val command = if (root) {
            arrayOf("su", "-c", cmd)
        } else {
            arrayOf("sh", "-c", cmd)
        }

        var process: Process? = null

        val job = launch(Dispatchers.IO) {
            try {
                process = Runtime.getRuntime().exec(command)
                process!!.inputStream.bufferedReader().useLines { lines ->
                    for (line in lines) {
                        if (!isActive) break
                        trySend(line)
                    }
                }
            } finally {
                close()
            }
        }

        awaitClose {
            job.cancel()
            process?.destroy()
        }
    }
}

package com.devtools.android.core

import android.os.Build

/**
 * Detects whether the device is rooted by checking:
 * 1. Known su binary paths
 * 2. Build tags containing "test-keys"
 * 3. `which su` via Runtime.exec fallback
 *
 * Constructor params allow injecting fakes in unit tests.
 */
class RootDetector(
    private val suPathExists: (String) -> Boolean = { path -> java.io.File(path).exists() },
    private val buildTagsContainTestKeys: () -> Boolean = {
        Build.TAGS?.contains("test-keys") == true
    }
) {
    fun check(): Boolean {
        // 1. Check known su paths
        val suPaths = listOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/su/bin/su"
        )
        if (suPaths.any { suPathExists(it) }) return true

        // 2. Check build tags
        if (buildTagsContainTestKeys()) return true

        // 3. Fallback: `which su` via Runtime.exec
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("which", "su"))
            val output = process.inputStream.bufferedReader().readText().trim()
            process.waitFor()
            output.isNotEmpty()
        } catch (_: Exception) {
            false
        }
    }

    companion object {
        val isRooted: Boolean by lazy { RootDetector().check() }
    }
}

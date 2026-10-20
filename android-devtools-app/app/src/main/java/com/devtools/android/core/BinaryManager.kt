package com.devtools.android.core

import android.content.Context
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.devtools.android.BuildConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

private val Context.binaryPrefs by preferencesDataStore(name = "binary_prefs")

/**
 * Manages the extraction and lifecycle of bundled native binaries from `assets/bin/`
 * into `context.filesDir/bin/` where they can be executed on the device.
 *
 * Call [ensureBinaries] once at startup (on a root-detected device) before invoking
 * any tool that depends on frida-server, nmap, or busybox.
 */
object BinaryManager {

    private val BIN_VERSION_KEY = stringPreferencesKey("bin_version")

    private val ASSET_BINARIES = listOf(
        "frida-server-arm64",
        "nmap-arm64",
        "busybox-arm64"
    )

    /**
     * Ensures that all bundled binaries are extracted to `context.filesDir/bin/` and
     * are marked executable. Extraction is skipped when the stored version hash already
     * matches [BuildConfig.VERSION_CODE], so subsequent launches are fast.
     *
     * @return `true` if binaries are ready; `false` if an [IOException] occurred
     *         (e.g. the device storage is full).
     */
    suspend fun ensureBinaries(context: Context): Boolean = withContext(Dispatchers.IO) {
        val currentVersion = BuildConfig.VERSION_CODE.toString()

        // Read the stored version hash from DataStore.
        val storedVersion = try {
            context.binaryPrefs.data.first()[BIN_VERSION_KEY]
        } catch (e: Exception) {
            null
        }

        if (storedVersion == currentVersion) {
            // Binaries already extracted for this version — nothing to do.
            return@withContext true
        }

        // Prepare the output directory.
        val binDir = File(context.filesDir, "bin")
        try {
            if (!binDir.exists()) {
                binDir.mkdirs()
            }
        } catch (e: IOException) {
            return@withContext false
        }

        // Copy each binary from assets to filesDir/bin/.
        for (name in ASSET_BINARIES) {
            try {
                val assetPath = "bin/$name"
                val outFile = File(binDir, name)
                context.assets.open(assetPath).use { input ->
                    FileOutputStream(outFile).use { output ->
                        input.copyTo(output)
                    }
                }
            } catch (e: IOException) {
                return@withContext false
            }
        }

        // Mark all binaries executable via root chmod.
        val binPath = binDir.absolutePath
        val chmodTargets = ASSET_BINARIES.joinToString(" ") { "$binPath/$it" }
        ShellExecutor.execCollect(
            cmd = "chmod +x $chmodTargets",
            root = true
        )

        // Persist the new version hash so we skip extraction on the next launch.
        try {
            context.binaryPrefs.edit { prefs ->
                prefs[BIN_VERSION_KEY] = currentVersion
            }
        } catch (e: Exception) {
            // Non-fatal: binaries are already in place; version check will just re-run next time.
        }

        true
    }

    /**
     * Returns the absolute path to the extracted binary named [name] inside
     * `context.filesDir/bin/`. Does not verify that the file exists.
     */
    fun binaryPath(name: String, context: Context): String =
        "${context.filesDir.absolutePath}/bin/$name"
}

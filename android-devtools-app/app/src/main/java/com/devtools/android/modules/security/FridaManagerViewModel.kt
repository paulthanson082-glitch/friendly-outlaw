package com.devtools.android.modules.security

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.devtools.android.core.BinaryManager
import com.devtools.android.core.ShellExecutor
import com.devtools.android.core.ShellResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

/** Represents a process visible to frida-ps. */
data class FridaProcess(val pid: Int, val name: String)

/** Lifecycle state of the Frida server. */
sealed class FridaState {
    object Idle : FridaState()
    object Starting : FridaState()
    data class Running(val pid: Int) : FridaState()
    data class Error(val msg: String) : FridaState()
}

class FridaManagerViewModel : ViewModel() {

    private val _state = MutableStateFlow<FridaState>(FridaState.Idle)
    val state: StateFlow<FridaState> = _state.asStateFlow()

    private val _processes = MutableStateFlow<List<FridaProcess>>(emptyList())
    val processes: StateFlow<List<FridaProcess>> = _processes.asStateFlow()

    private val _injectLog = MutableStateFlow<String?>(null)
    /** Last injection result or error message, null when idle. */
    val injectLog: StateFlow<String?> = _injectLog.asStateFlow()

    /** Start frida-server as a background daemon via su. */
    fun startServer(context: Context) {
        if (_state.value is FridaState.Starting || _state.value is FridaState.Running) return
        _state.value = FridaState.Starting

        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                val path = BinaryManager.binaryPath("frida-server-arm64", context)
                // Ensure the binary is executable
                ShellExecutor.execCollect("chmod +x $path", root = true)

                val result = ShellExecutor.execCollect("$path &", root = true)
                when (result) {
                    is ShellResult.Success -> {
                        // Give the server a moment to start, then refresh process list
                        kotlinx.coroutines.delay(800)
                        refreshProcesses()
                    }
                    is ShellResult.Failed -> {
                        val errText = result.stderr
                        _state.value = if (
                            errText.contains("Unable to handle 64-bit", ignoreCase = true) ||
                            errText.contains("version mismatch", ignoreCase = true)
                        ) {
                            FridaState.Error("Frida version mismatch — reinstall app")
                        } else {
                            FridaState.Error(errText.ifBlank { "Failed to start frida-server (exit ${result.exitCode})" })
                        }
                    }
                    is ShellResult.BinaryMissing -> {
                        _state.value = FridaState.Error("frida-server binary not found — reinstall app")
                    }
                    ShellResult.RootRequired -> {
                        _state.value = FridaState.Error("Root access required to start frida-server")
                    }
                }
            }
        }
    }

    /** Kill frida-server via pkill. */
    fun stopServer() {
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                ShellExecutor.execCollect("pkill frida-server", root = true)
                _state.value = FridaState.Idle
                _processes.value = emptyList()
            }
        }
    }

    /** Refresh the frida-ps process list; marks server Running on success. */
    fun refreshProcesses() {
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                val result = ShellExecutor.execCollect("frida-ps", root = true)
                when (result) {
                    is ShellResult.Success -> {
                        val parsed = parseFridaPs(result.output)
                        _processes.value = parsed
                        // If we got results the server is running; pick the first non-zero pid as representative
                        if (_state.value !is FridaState.Running) {
                            _state.value = FridaState.Running(parsed.firstOrNull()?.pid ?: 0)
                        }
                    }
                    is ShellResult.Failed -> {
                        // frida-ps failed — server may not be running yet, keep Starting or set Error
                        if (_state.value is FridaState.Starting) {
                            _state.value = FridaState.Error(
                                result.stderr.ifBlank { "frida-ps failed — is frida-server running?" }
                            )
                        }
                    }
                    else -> { /* ignore */ }
                }
            }
        }
    }

    /**
     * Write [script] to a temp file in [context.cacheDir] and run
     * `frida -p $pid -l $scriptPath` via root shell.
     */
    fun injectScript(pid: Int, script: String, context: Context) {
        _injectLog.value = null
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                val scriptFile = File(context.cacheDir, "frida_inject_$pid.js")
                try {
                    scriptFile.writeText(script)
                } catch (e: Exception) {
                    _injectLog.value = "Failed to write script: ${e.message}"
                    return@withContext
                }
                val scriptPath = scriptFile.absolutePath
                val result = ShellExecutor.execCollect("frida -p $pid -l $scriptPath", root = true)
                _injectLog.value = when (result) {
                    is ShellResult.Success -> result.output.ifBlank { "Injection complete." }
                    is ShellResult.Failed -> "Injection failed (exit ${result.exitCode}): ${result.stderr}"
                    is ShellResult.BinaryMissing -> "frida CLI not found on PATH"
                    ShellResult.RootRequired -> "Root access required"
                }
            }
        }
    }

    fun clearInjectLog() {
        _injectLog.value = null
    }

    // ---------------------------------------------------------------------------
    // Parsing helpers
    // ---------------------------------------------------------------------------

    /**
     * Parses `frida-ps` output.
     *
     * Expected format (header line followed by data lines):
     * ```
     *  PID  Name
     * ----  ----
     * 1234  com.example.app
     * ```
     */
    private fun parseFridaPs(output: String): List<FridaProcess> {
        val lines = output.lines()
        return lines
            .drop(1) // skip header
            .mapNotNull { line ->
                val trimmed = line.trim()
                if (trimmed.isEmpty() || trimmed.startsWith("-")) return@mapNotNull null
                // Split on first run of whitespace: PID  Name
                val parts = trimmed.split(Regex("\\s+"), limit = 2)
                if (parts.size < 2) return@mapNotNull null
                val pid = parts[0].toIntOrNull() ?: return@mapNotNull null
                FridaProcess(pid = pid, name = parts[1].trim())
            }
    }
}

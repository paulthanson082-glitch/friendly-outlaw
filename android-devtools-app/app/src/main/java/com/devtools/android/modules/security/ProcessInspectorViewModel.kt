package com.devtools.android.modules.security

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.devtools.android.core.ShellExecutor
import com.devtools.android.core.ShellResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * A single entry in the running process list.
 *
 * @param pid   Process ID.
 * @param ppid  Parent process ID.
 * @param name  Process/command name.
 * @param user  Owner user name.
 * @param rss   Resident set size in kilobytes.
 */
data class ProcessEntry(
    val pid: Int,
    val ppid: Int,
    val name: String,
    val user: String,
    val rss: Long
)

class ProcessInspectorViewModel : ViewModel() {

    /** Full unfiltered list loaded from the device. */
    private val _allProcesses = MutableStateFlow<List<ProcessEntry>>(emptyList())

    /** Filtered view exposed to the UI. */
    private val _processes = MutableStateFlow<List<ProcessEntry>>(emptyList())
    val processes: StateFlow<List<ProcessEntry>> = _processes.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    private var currentFilter = ""

    init {
        refresh()
    }

    /** Re-load the process list from the device. */
    fun refresh() {
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                _isLoading.value = true
                _error.value = null

                val result = ShellExecutor.execCollect(
                    cmd = "ps -A -o PID,PPID,USER,RSS,NAME",
                    root = true
                )

                when (result) {
                    is ShellResult.Success -> {
                        val parsed = parsePs(result.output)
                        _allProcesses.value = parsed
                        applyFilter(currentFilter)
                    }
                    is ShellResult.Failed -> {
                        _error.value = result.stderr.ifBlank {
                            "ps command failed (exit ${result.exitCode})"
                        }
                    }
                    is ShellResult.BinaryMissing -> {
                        _error.value = "ps binary not found: ${result.name}"
                    }
                    ShellResult.RootRequired -> {
                        _error.value = "Root access required to list all processes"
                    }
                }

                _isLoading.value = false
            }
        }
    }

    /** Filter the process list by [query] (matches name or PID). */
    fun filter(query: String) {
        currentFilter = query
        applyFilter(query)
    }

    /** Send SIGKILL to the process with [pid]. */
    fun kill(pid: Int) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) {
                ShellExecutor.execCollect("kill -9 $pid", root = true)
                // Refresh the list after a short delay so the killed process disappears
                kotlinx.coroutines.delay(400)
                refresh()
            }
        }
    }

    fun clearError() {
        _error.value = null
    }

    // ---------------------------------------------------------------------------
    // Private helpers
    // ---------------------------------------------------------------------------

    private fun applyFilter(query: String) {
        val all = _allProcesses.value
        _processes.value = if (query.isBlank()) {
            all
        } else {
            val lower = query.lowercase()
            all.filter { entry ->
                entry.name.lowercase().contains(lower) ||
                    entry.pid.toString().contains(lower) ||
                    entry.user.lowercase().contains(lower)
            }
        }
    }

    /**
     * Parses the output of `ps -A -o PID,PPID,USER,RSS,NAME`.
     *
     * Expected format (first line is the header):
     * ```
     * PID   PPID USER         RSS NAME
     *   1      0 root        1024 /init
     * 123    456 shell        512 sh
     * ```
     */
    private fun parsePs(output: String): List<ProcessEntry> {
        val lines = output.lines()
        if (lines.size < 2) return emptyList()
        // Skip the header line
        return lines.drop(1).mapNotNull { line ->
            if (line.isBlank()) return@mapNotNull null
            // Split on whitespace; NAME may contain spaces so limit to 5 parts
            val parts = line.trim().split(Regex("\\s+"), limit = 5)
            if (parts.size < 5) return@mapNotNull null
            val pid = parts[0].toIntOrNull() ?: return@mapNotNull null
            val ppid = parts[1].toIntOrNull() ?: return@mapNotNull null
            val user = parts[2]
            val rss = parts[3].toLongOrNull() ?: 0L
            val name = parts[4]
            ProcessEntry(pid = pid, ppid = ppid, user = user, rss = rss, name = name)
        }
    }
}

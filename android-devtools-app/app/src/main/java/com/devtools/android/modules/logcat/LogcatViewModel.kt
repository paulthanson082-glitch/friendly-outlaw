package com.devtools.android.modules.logcat

import android.content.Context
import android.os.Environment
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.devtools.android.core.ShellExecutor
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** State of the logcat capture session. */
sealed class LogcatState {
    object Idle : LogcatState()
    object Running : LogcatState()
    object PermissionDenied : LogcatState()
}

/** Maximum number of [LogLine] entries kept in memory. */
private const val MAX_LINES = 2000

class LogcatViewModel : ViewModel() {

    private val _lines = MutableStateFlow<List<LogLine>>(emptyList())
    val lines: StateFlow<List<LogLine>> = _lines.asStateFlow()

    private val _state = MutableStateFlow<LogcatState>(LogcatState.Idle)
    val state: StateFlow<LogcatState> = _state.asStateFlow()

    private var captureJob: Job? = null

    /**
     * Starts streaming logcat output.
     *
     * @param filter Optional logcat filter expression appended to the command
     *               (e.g. `"*:E"` or `"MyTag:D"`).
     */
    fun startCapture(filter: String = "") {
        captureJob?.cancel()
        if (_state.value is LogcatState.Running) return
        _state.value = LogcatState.Running

        var lineCount = 0

        captureJob = viewModelScope.launch {
            val cmd = buildString {
                append("logcat -v threadtime")
                if (filter.isNotBlank()) append(" $filter")
            }

            // After 2 s with no output, assume the app lacks READ_LOGS permission.
            val permissionCheckJob = launch {
                delay(2_000)
                if (lineCount == 0) {
                    _state.value = LogcatState.PermissionDenied
                }
            }

            try {
                ShellExecutor.exec(cmd).collect { rawLine ->
                    lineCount++
                    val logLine = LogLine.parse(rawLine)
                    val current = _lines.value
                    val updated = if (current.size >= MAX_LINES) {
                        current.drop(1) + logLine
                    } else {
                        current + logLine
                    }
                    _lines.value = updated
                }
            } finally {
                permissionCheckJob.cancel()
                if (_state.value is LogcatState.Running) {
                    _state.value = LogcatState.Idle
                }
            }
        }
    }

    /** Stops the active logcat capture. */
    fun stopCapture() {
        captureJob?.cancel()
        captureJob = null
        _state.value = LogcatState.Idle
    }

    /** Clears all captured lines. */
    fun clear() {
        _lines.value = emptyList()
    }

    /**
     * Saves all currently captured lines to a timestamped file in the Downloads directory.
     * Silently swallows errors (e.g. missing WRITE_EXTERNAL_STORAGE on older devices).
     */
    fun saveToFile(context: Context) {
        val lines = _lines.value
        if (lines.isEmpty()) return

        viewModelScope.launch(Dispatchers.IO) {
            try {
                val downloadsDir = Environment.getExternalStoragePublicDirectory(
                    Environment.DIRECTORY_DOWNLOADS
                )
                downloadsDir.mkdirs()
                val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
                val file = File(downloadsDir, "logcat_$timestamp.txt")
                file.bufferedWriter().use { writer ->
                    lines.forEach { line ->
                        writer.write("${line.timestamp} ${line.pid} ${line.level.name} ${line.tag}: ${line.message}")
                        writer.newLine()
                    }
                }
            } catch (_: Exception) {
                // Best-effort: ignore write failures
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        stopCapture()
    }
}

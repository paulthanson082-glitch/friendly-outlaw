package com.devtools.android.modules.terminal

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.devtools.android.core.RootDetector
import com.devtools.android.core.ShellExecutor
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

private const val MAX_LINES = 1000

open class ShellTerminalViewModel : ViewModel() {

    private val _outputLines = MutableStateFlow<List<String>>(emptyList())
    val outputLines: StateFlow<List<String>> = _outputLines.asStateFlow()

    private val _isRootMode = MutableStateFlow(false)
    val isRootMode: StateFlow<Boolean> = _isRootMode.asStateFlow()

    private val _commandHistory = mutableListOf<String>()
    val commandHistory: List<String> get() = _commandHistory.toList()

    /** Enable or disable root mode. No-op if device is not rooted. */
    fun setRootMode(enabled: Boolean) {
        if (enabled && !RootDetector.isRooted) return
        _isRootMode.value = enabled
    }

    /**
     * Appends `"$ $input"` to output lines, executes [input] via [ShellExecutor.exec],
     * and collects each output line into [outputLines] (capped at [MAX_LINES]).
     */
    open fun sendCommand(input: String) {
        if (input.isBlank()) return
        _commandHistory.add(input)
        appendLine("$ $input")

        viewModelScope.launch {
            ShellExecutor.exec(input, root = _isRootMode.value).collect { line ->
                appendLine(line)
            }
        }
    }

    /** Clears all output lines. */
    fun clearOutput() {
        _outputLines.value = emptyList()
    }

    protected fun appendLine(line: String) {
        val current = _outputLines.value
        _outputLines.value = if (current.size >= MAX_LINES) {
            current.drop(1) + line
        } else {
            current + line
        }
    }
}

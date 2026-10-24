package com.devtools.android.modules.files

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.devtools.android.core.RootDetector
import com.devtools.android.core.ShellExecutor
import com.devtools.android.core.ShellResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

data class FileEntry(
    val name: String,
    val path: String,
    val isDir: Boolean,
    val sizeBytes: Long,
    val permissions: String
)

class FileBrowserViewModel : ViewModel() {

    private val _currentPath = MutableStateFlow("/sdcard")
    val currentPath: StateFlow<String> = _currentPath.asStateFlow()

    private val _entries = MutableStateFlow<List<FileEntry>>(emptyList())
    val entries: StateFlow<List<FileEntry>> = _entries.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    init {
        navigate("/sdcard")
    }

    fun navigate(path: String) {
        _currentPath.value = path
        _error.value = null
        viewModelScope.launch {
            if (RootDetector.isRooted) {
                navigateWithRoot(path)
            } else {
                navigateWithoutRoot(path)
            }
        }
    }

    fun navigateUp() {
        val parent = File(_currentPath.value).parent ?: "/"
        navigate(parent)
    }

    private suspend fun navigateWithoutRoot(path: String) {
        try {
            val dir = File(path)
            val files = withContext(Dispatchers.IO) { dir.listFiles() }
            if (files == null) {
                _error.value = "Cannot read directory: $path"
                _entries.value = emptyList()
                return
            }
            _entries.value = files
                .map { file ->
                    FileEntry(
                        name = file.name,
                        path = file.absolutePath,
                        isDir = file.isDirectory,
                        sizeBytes = if (file.isFile) file.length() else 0L,
                        permissions = buildPermissions(file)
                    )
                }
                .sortedWith(compareByDescending<FileEntry> { it.isDir }.thenBy { it.name })
        } catch (e: SecurityException) {
            _error.value = "Permission denied: $path"
            _entries.value = emptyList()
        } catch (e: Exception) {
            _error.value = e.message ?: "Unknown error"
            _entries.value = emptyList()
        }
    }

    private suspend fun navigateWithRoot(path: String) {
        when (val result = withContext(Dispatchers.IO) { ShellExecutor.execCollect("ls -la \"$path\"", root = true) }) {
            is ShellResult.Success -> {
                _entries.value = parseLsOutput(result.output, path)
            }
            is ShellResult.Failed -> {
                _error.value = result.stderr.ifBlank { "Failed to list directory" }
                _entries.value = emptyList()
            }
            is ShellResult.BinaryMissing -> {
                _error.value = "ls binary not found"
                _entries.value = emptyList()
            }
            is ShellResult.RootRequired -> {
                // Fall back to non-root listing
                navigateWithoutRoot(path)
            }
        }
    }

    private fun parseLsOutput(output: String, basePath: String): List<FileEntry> {
        val entries = mutableListOf<FileEntry>()
        for (line in output.lines()) {
            if (line.startsWith("total") || line.isBlank()) continue
            // ls -la columns: permissions links owner group size date[3] name
            val parts = line.split(Regex("\\s+"), limit = 9)
            if (parts.size < 9) continue
            val permissions = parts[0]
            val sizeStr = parts[4]
            val name = parts[8].trim()
            if (name == "." || name == "..") continue
            val isDir = permissions.startsWith("d")
            val sizeBytes = sizeStr.toLongOrNull() ?: 0L
            val fullPath = if (basePath.endsWith("/")) "$basePath$name" else "$basePath/$name"
            entries.add(
                FileEntry(
                    name = name,
                    path = fullPath,
                    isDir = isDir,
                    sizeBytes = sizeBytes,
                    permissions = permissions
                )
            )
        }
        return entries.sortedWith(compareByDescending<FileEntry> { it.isDir }.thenBy { it.name })
    }

    /** Runs `busybox ${algo}sum <path>` and emits the result line. */
    fun checksum(path: String, algo: String): Flow<String> = flow {
        when (val result = ShellExecutor.execCollect(
            "busybox ${algo}sum \"$path\"",
            root = RootDetector.isRooted
        )) {
            is ShellResult.Success -> emit(result.output)
            is ShellResult.Failed -> emit("Error: ${result.stderr.ifBlank { "Command failed" }}")
            is ShellResult.BinaryMissing -> emit("Error: busybox not found")
            is ShellResult.RootRequired -> emit("Error: Root required")
        }
    }.flowOn(Dispatchers.IO)

    private fun buildPermissions(file: File): String = buildString {
        append(if (file.isDirectory) "d" else "-")
        append(if (file.canRead()) "r" else "-")
        append(if (file.canWrite()) "w" else "-")
        append(if (file.canExecute()) "x" else "-")
    }
}

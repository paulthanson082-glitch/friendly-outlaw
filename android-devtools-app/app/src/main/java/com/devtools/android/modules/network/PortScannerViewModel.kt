package com.devtools.android.modules.network

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.devtools.android.core.RootDetector
import com.devtools.android.core.ShellExecutor
import com.devtools.android.core.ShellResult
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.supervisorScope
import kotlinx.coroutines.withContext
import java.net.InetSocketAddress
import java.net.Socket

sealed class PortScanState {
    object Idle : PortScanState()
    data class Scanning(val progress: Float, val openPorts: List<Int>) : PortScanState()
    data class Done(val openPorts: List<Int>) : PortScanState()
    object Cancelled : PortScanState()
    data class Error(val message: String) : PortScanState()
}

class PortScannerViewModel(private val context: Context) : ViewModel() {

    private val _state = MutableStateFlow<PortScanState>(PortScanState.Idle)
    val state: StateFlow<PortScanState> = _state.asStateFlow()

    private var scanJob: Job? = null

    /** Non-root TCP connect scan using parallel Socket connections. */
    fun scan(host: String, portRange: IntRange, timeoutMs: Int) {
        scanJob?.cancel()
        _state.value = PortScanState.Scanning(0f, emptyList())

        scanJob = viewModelScope.launch {
            val openPorts = mutableListOf<Int>()
            val ports = portRange.toList()
            val total = ports.size
            var scanned = 0

            try {
                withContext(Dispatchers.IO) {
                    for (batch in ports.chunked(50)) {
                        ensureActive()
                        supervisorScope {
                            val deferreds = batch.map { port ->
                                async {
                                    try {
                                        Socket().use { socket ->
                                            socket.connect(
                                                InetSocketAddress(host, port),
                                                timeoutMs
                                            )
                                            port
                                        }
                                    } catch (_: Exception) {
                                        null
                                    }
                                }
                            }
                            val results = deferreds.awaitAll()
                            openPorts.addAll(results.filterNotNull())
                        }
                        scanned += batch.size
                        val progress = scanned.toFloat() / total
                        _state.value = PortScanState.Scanning(progress, openPorts.toList().sorted())
                    }
                }
                _state.value = PortScanState.Done(openPorts.sorted())
            } catch (e: CancellationException) {
                _state.value = PortScanState.Cancelled
                throw e
            } catch (e: Exception) {
                _state.value = PortScanState.Error(e.message ?: "Scan failed")
            }
        }
    }

    /** Cancels an in-progress scan. */
    fun cancel() {
        scanJob?.cancel()
        _state.value = PortScanState.Cancelled
    }

    /** Resets state back to Idle so the user can start a new scan. */
    fun reset() {
        scanJob?.cancel()
        _state.value = PortScanState.Idle
    }

    /** Root-only nmap scan. Only callable when [RootDetector.isRooted] is true. */
    fun nmapScan(target: String, args: String) {
        if (!RootDetector.isRooted) return
        scanJob?.cancel()
        _state.value = PortScanState.Scanning(0f, emptyList())

        scanJob = viewModelScope.launch {
            when (val result = ShellExecutor.execCollect("nmap $args $target", root = true)) {
                is ShellResult.Success -> {
                    val open = Regex("""(\d+)/tcp\s+open""")
                        .findAll(result.output)
                        .map { it.groupValues[1].toInt() }
                        .sorted()
                        .toList()
                    _state.value = PortScanState.Done(open)
                }
                is ShellResult.BinaryMissing ->
                    _state.value = PortScanState.Error("nmap binary not found on device")
                is ShellResult.RootRequired ->
                    _state.value = PortScanState.Error("Root access required")
                is ShellResult.Failed ->
                    _state.value = PortScanState.Error(result.stderr.ifBlank { "nmap failed" })
            }
        }
    }

    class Factory(private val context: Context) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            PortScannerViewModel(context.applicationContext) as T
    }
}

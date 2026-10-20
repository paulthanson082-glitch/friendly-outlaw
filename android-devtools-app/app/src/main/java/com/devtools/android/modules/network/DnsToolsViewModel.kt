package com.devtools.android.modules.network

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.devtools.android.core.ShellExecutor
import com.devtools.android.core.ShellResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.net.InetAddress

data class DnsResult(
    val addresses: List<String> = emptyList(),
    val reversePtrs: List<String> = emptyList(),
    val whoisOutput: String = "",
)

class DnsToolsViewModel : ViewModel() {

    private val _result = MutableStateFlow<DnsResult?>(null)
    val result: StateFlow<DnsResult?> = _result.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    /** Performs a forward DNS lookup, reverse PTR lookups, and a whois query. */
    fun lookup(host: String) {
        if (host.isBlank()) return
        _isLoading.value = true
        _error.value = null
        _result.value = null

        viewModelScope.launch(Dispatchers.IO) {
            try {
                val addresses = InetAddress.getAllByName(host)
                    .mapNotNull { it.hostAddress }
                    .filter { it.isNotBlank() }

                val reversePtrs = addresses.map { ip ->
                    try {
                        InetAddress.getByName(ip).canonicalHostName
                    } catch (_: Exception) {
                        ip
                    }
                }

                val whoisOutput = when (val r = ShellExecutor.execCollect("busybox whois $host")) {
                    is ShellResult.Success -> r.output.trim()
                    is ShellResult.BinaryMissing -> "busybox not available on this device"
                    is ShellResult.Failed -> "whois failed (exit ${r.exitCode}): ${r.stderr}"
                    is ShellResult.RootRequired -> "Root required"
                }

                _result.value = DnsResult(
                    addresses = addresses,
                    reversePtrs = reversePtrs,
                    whoisOutput = whoisOutput,
                )
            } catch (e: Exception) {
                _error.value = e.message ?: "DNS lookup failed"
            } finally {
                _isLoading.value = false
            }
        }
    }
}

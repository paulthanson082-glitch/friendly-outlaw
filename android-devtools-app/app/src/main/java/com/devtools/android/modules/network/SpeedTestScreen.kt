package com.devtools.android.modules.network

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.devtools.android.core.ShellExecutor
import com.devtools.android.core.ShellResult
import com.devtools.android.ui.components.ErrorCard
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

// ── Model ──────────────────────────────────────────────────────────────────────

enum class SpeedTestMode(val label: String, val extraArgs: String) {
    Upload("Upload", ""),
    Download("Download", "-R"),
    Both("Both", ""),
    Udp("UDP", "-u"),
}

data class SpeedTestResult(
    val bandwidth: String,
    val rawOutput: String,
)

sealed class SpeedTestState {
    object Idle : SpeedTestState()
    object Running : SpeedTestState()
    data class Success(val result: SpeedTestResult) : SpeedTestState()
    data class Error(val message: String) : SpeedTestState()
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

class SpeedTestViewModel : ViewModel() {

    private val _state = MutableStateFlow<SpeedTestState>(SpeedTestState.Idle)
    val state: StateFlow<SpeedTestState> = _state.asStateFlow()

    private val bandwidthRegex = Regex("""\d+(\.\d+)?\s+[KMG]bits/sec""")

    fun runTest(host: String, port: Int, mode: SpeedTestMode) {
        _state.value = SpeedTestState.Running

        viewModelScope.launch(Dispatchers.IO) {
            when (mode) {
                SpeedTestMode.Both -> runBothDirections(host, port)
                else -> runSingleTest(host, port, mode.extraArgs)
            }
        }
    }

    private suspend fun runSingleTest(host: String, port: Int, extraArgs: String) {
        val cmd = buildString {
            append("iperf3 -c $host -p $port")
            if (extraArgs.isNotBlank()) append(" $extraArgs")
        }
        when (val result = ShellExecutor.execCollect(cmd)) {
            is ShellResult.Success -> {
                val bandwidth = bandwidthRegex.findAll(result.output).lastOrNull()?.value ?: "—"
                _state.value = SpeedTestState.Success(
                    SpeedTestResult(bandwidth = bandwidth, rawOutput = result.output)
                )
            }
            is ShellResult.BinaryMissing ->
                _state.value = SpeedTestState.Error(
                    "iperf3 is not installed on this device. " +
                            "Install it or use a terminal to run iperf3 manually."
                )
            is ShellResult.Failed ->
                _state.value = SpeedTestState.Error(
                    result.stderr.ifBlank { "iperf3 exited with code ${result.exitCode}" }
                )
            is ShellResult.RootRequired ->
                _state.value = SpeedTestState.Error("Root required")
        }
    }

    private suspend fun runBothDirections(host: String, port: Int) {
        // Upload first, then download
        val uploadCmd = "iperf3 -c $host -p $port"
        val downloadCmd = "iperf3 -c $host -p $port -R"

        val uploadResult = ShellExecutor.execCollect(uploadCmd)
        val downloadResult = ShellExecutor.execCollect(downloadCmd)

        val uploadBw = (uploadResult as? ShellResult.Success)?.let {
            bandwidthRegex.findAll(it.output).lastOrNull()?.value
        } ?: "—"
        val downloadBw = (downloadResult as? ShellResult.Success)?.let {
            bandwidthRegex.findAll(it.output).lastOrNull()?.value
        } ?: "—"

        val combined = buildString {
            append("=== Upload ===\n")
            if (uploadResult is ShellResult.Success) append(uploadResult.output)
            else if (uploadResult is ShellResult.BinaryMissing) append("iperf3 not found")
            append("\n\n=== Download ===\n")
            if (downloadResult is ShellResult.Success) append(downloadResult.output)
        }

        if (uploadResult is ShellResult.BinaryMissing) {
            _state.value = SpeedTestState.Error(
                "iperf3 is not installed on this device. " +
                        "Install it or use a terminal to run iperf3 manually."
            )
            return
        }

        _state.value = SpeedTestState.Success(
            SpeedTestResult(
                bandwidth = "↑ $uploadBw  ↓ $downloadBw",
                rawOutput = combined,
            )
        )
    }

    fun reset() {
        _state.value = SpeedTestState.Idle
    }
}

// ── Screen ────────────────────────────────────────────────────────────────────

@Composable
fun SpeedTestScreen(vm: SpeedTestViewModel = viewModel()) {
    val state by vm.state.collectAsState()

    var serverHost by rememberSaveable { mutableStateOf("") }
    var serverPort by rememberSaveable { mutableStateOf("5201") }
    var mode by rememberSaveable { mutableStateOf(SpeedTestMode.Download) }

    val isRunning = state is SpeedTestState.Running

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 16.dp),
    ) {
        item {
            Spacer(modifier = Modifier.height(16.dp))

            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                )
            ) {
                Text(
                    text = "Note: requires an iperf3 server running on the target host. " +
                            "Start one with: iperf3 -s",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onPrimaryContainer,
                    modifier = Modifier.padding(12.dp),
                )
            }
        }

        item {
            Spacer(modifier = Modifier.height(12.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedTextField(
                    value = serverHost,
                    onValueChange = { serverHost = it },
                    label = { Text("Server Host") },
                    singleLine = true,
                    modifier = Modifier.weight(2f),
                    enabled = !isRunning,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri),
                )
                OutlinedTextField(
                    value = serverPort,
                    onValueChange = { serverPort = it.filter(Char::isDigit) },
                    label = { Text("Port") },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                    enabled = !isRunning,
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                )
            }
        }

        item {
            Spacer(modifier = Modifier.height(8.dp))
            Text("Mode", fontWeight = FontWeight.Medium)
            Spacer(modifier = Modifier.height(4.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                SpeedTestMode.entries.forEach { m ->
                    FilterChip(
                        selected = mode == m,
                        onClick = { mode = m },
                        label = { Text(m.label) },
                        enabled = !isRunning,
                    )
                }
            }
        }

        item {
            Spacer(modifier = Modifier.height(8.dp))
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Button(
                    onClick = {
                        val port = serverPort.toIntOrNull() ?: 5201
                        vm.runTest(serverHost.trim(), port, mode)
                    },
                    enabled = !isRunning && serverHost.isNotBlank(),
                    modifier = Modifier.weight(1f),
                ) {
                    Text(if (isRunning) "Running…" else "Start Test")
                }
                if (state !is SpeedTestState.Idle) {
                    Spacer(modifier = Modifier.width(0.dp))
                }
            }
        }

        if (isRunning) {
            item {
                Spacer(modifier = Modifier.height(24.dp))
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    CircularProgressIndicator()
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("Running iperf3…", style = MaterialTheme.typography.bodyMedium)
                }
            }
        }

        if (state is SpeedTestState.Error) {
            item {
                Spacer(modifier = Modifier.height(8.dp))
                ErrorCard(
                    message = (state as SpeedTestState.Error).message,
                    onRetry = { vm.reset() }
                )
            }
        }

        if (state is SpeedTestState.Success) {
            val success = state as SpeedTestState.Success
            item {
                Spacer(modifier = Modifier.height(16.dp))
                Text("Result", fontWeight = FontWeight.Bold)
                HorizontalDivider(modifier = Modifier.padding(top = 2.dp, bottom = 8.dp))
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text(
                            text = "Bandwidth: ${success.result.bandwidth}",
                            style = MaterialTheme.typography.titleMedium,
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        HorizontalDivider()
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = success.result.rawOutput,
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    onClick = { vm.reset() },
                    modifier = Modifier.fillMaxWidth(),
                ) {
                    Text("New Test")
                }
            }
        }

        item { Spacer(modifier = Modifier.height(16.dp)) }
    }
}

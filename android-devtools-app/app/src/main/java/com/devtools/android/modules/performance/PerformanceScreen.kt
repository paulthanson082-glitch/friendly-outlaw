package com.devtools.android.modules.performance

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel

@Composable
fun PerformanceScreen(
    vm: PerformanceViewModel = viewModel(
        factory = PerformanceViewModel.Factory(LocalContext.current)
    )
) {
    LaunchedEffect(Unit) {
        vm.startMonitoring()
    }

    val data by vm.performanceData.collectAsState()

    LazyColumn(modifier = Modifier.fillMaxSize()) {

        // ── CPU Usage ─────────────────────────────────────────────────────────
        item { SectionHeader("CPU Usage") }
        item {
            Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                Row(modifier = Modifier.fillMaxWidth()) {
                    Text(text = "Usage", modifier = Modifier.weight(1f))
                    Text(text = "${"%.1f".format(data.cpuUsagePercent)}%")
                }
                Spacer(modifier = Modifier.height(6.dp))
                LinearProgressIndicator(
                    progress = { (data.cpuUsagePercent / 100f).coerceIn(0f, 1f) },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }

        // ── Memory (RAM) ──────────────────────────────────────────────────────
        item { SectionHeader("Memory (RAM)") }
        item {
            val ramFraction = if (data.ramTotalMb > 0) {
                data.ramUsedMb.toFloat() / data.ramTotalMb.toFloat()
            } else 0f
            Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)) {
                Row(modifier = Modifier.fillMaxWidth()) {
                    Text(text = "Used / Total", modifier = Modifier.weight(1f))
                    Text(text = "${data.ramUsedMb} / ${data.ramTotalMb} MB")
                }
                Spacer(modifier = Modifier.height(6.dp))
                LinearProgressIndicator(
                    progress = { ramFraction.coerceIn(0f, 1f) },
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }

        // ── Battery ───────────────────────────────────────────────────────────
        if (data.batteryCurrentMa != 0) {
            item { SectionHeader("Battery") }
            item {
                ListItem(
                    headlineContent = { Text("Current", fontWeight = FontWeight.Medium) },
                    trailingContent = { Text("${data.batteryCurrentMa} mA") }
                )
            }
        }

        // ── Thermal Zones ─────────────────────────────────────────────────────
        if (data.thermalZones.isNotEmpty()) {
            item { SectionHeader("Thermal Zones") }
            items(data.thermalZones) { zone ->
                ListItem(
                    headlineContent = { Text(zone.name, fontWeight = FontWeight.Medium) },
                    trailingContent = { Text("${"%.1f".format(zone.tempC)} °C") }
                )
            }
        }

        // ── Top Processes (RSS) ───────────────────────────────────────────────
        if (data.topProcesses.isNotEmpty()) {
            item { SectionHeader("Top Processes (RSS)") }
            items(data.topProcesses) { process ->
                ListItem(
                    headlineContent = { Text(process.name, fontWeight = FontWeight.Medium) },
                    trailingContent = { Text("${process.rssKb} KB") }
                )
            }
        }

        item { Spacer(modifier = Modifier.height(16.dp)) }
    }
}

@Composable
private fun SectionHeader(title: String) {
    Column {
        Text(
            text = title,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.padding(start = 16.dp, top = 16.dp, end = 16.dp, bottom = 4.dp)
        )
        HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp))
    }
}

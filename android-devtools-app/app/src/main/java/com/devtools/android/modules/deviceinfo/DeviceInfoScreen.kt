package com.devtools.android.modules.deviceinfo

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ListItem
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.devtools.android.ui.components.ErrorCard

@Composable
fun DeviceInfoScreen(
    vm: DeviceInfoViewModel = viewModel(
        factory = DeviceInfoViewModel.Factory(LocalContext.current)
    )
) {
    val info by vm.deviceInfo.collectAsState()
    val hasError by vm.hasError.collectAsState()

    if (hasError) {
        ErrorCard(message = "Failed to read device information", onRetry = null)
        return
    }

    LazyColumn(modifier = Modifier.fillMaxSize()) {

        // ── Android ──────────────────────────────────────────────────────────
        item { SectionHeader("Android") }
        item { InfoItem(label = "Version", value = info.androidVersion) }
        item { InfoItem(label = "Build Fingerprint", value = info.buildFingerprint, multiLine = true) }
        item { InfoItem(label = "Kernel", value = info.kernel, multiLine = true) }

        // ── CPU ──────────────────────────────────────────────────────────────
        item { SectionHeader("CPU") }
        item { InfoItem(label = "Hardware", value = info.cpuHardware) }
        item { InfoItem(label = "Cores", value = info.cpuCores.toString()) }
        if (info.gpuClockFreq != null) {
            item { InfoItem(label = "GPU Clock", value = info.gpuClockFreq) }
        }

        // ── Memory ───────────────────────────────────────────────────────────
        item { SectionHeader("Memory") }
        item { InfoItem(label = "Total RAM", value = "${info.totalRamMb} MB") }
        item { InfoItem(label = "Available RAM", value = "${info.availRamMb} MB") }
        item {
            val usedMb = info.totalRamMb - info.availRamMb
            InfoItem(label = "Used RAM", value = "$usedMb MB")
        }

        // ── Storage ───────────────────────────────────────────────────────────
        item { SectionHeader("Storage") }
        item { InfoItem(label = "Total", value = "${"%.1f".format(info.storageTotalGb)} GB") }
        item { InfoItem(label = "Available", value = "${"%.1f".format(info.storageAvailGb)} GB") }
        item {
            val usedGb = info.storageTotalGb - info.storageAvailGb
            InfoItem(label = "Used", value = "${"%.1f".format(usedGb)} GB")
        }

        // ── Battery ──────────────────────────────────────────────────────────
        item { SectionHeader("Battery") }
        item { InfoItem(label = "Level", value = "${info.batteryLevel}%") }
        item { InfoItem(label = "Temperature", value = "${"%.1f".format(info.batteryTemp)} °C") }

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

@Composable
private fun InfoItem(label: String, value: String, multiLine: Boolean = false) {
    if (multiLine) {
        ListItem(
            headlineContent = { Text(text = label, fontWeight = FontWeight.Medium) },
            supportingContent = { Text(text = value) }
        )
    } else {
        ListItem(
            headlineContent = { Text(text = label, fontWeight = FontWeight.Medium) },
            trailingContent = { Text(text = value) }
        )
    }
}

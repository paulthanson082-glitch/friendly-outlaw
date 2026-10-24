package com.devtools.android.modules.network

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
fun NetworkInfoScreen(
    vm: NetworkInfoViewModel = viewModel(
        factory = NetworkInfoViewModel.Factory(LocalContext.current)
    )
) {
    val info by vm.networkInfo.collectAsState()
    val hasError by vm.hasError.collectAsState()

    if (hasError) {
        ErrorCard(
            message = "Failed to read network information",
            onRetry = { vm.refresh() }
        )
        return
    }

    LazyColumn(modifier = Modifier.fillMaxSize()) {

        // ── WiFi ─────────────────────────────────────────────────────────────
        item { SectionHeader("WiFi") }
        item { InfoRow("SSID", info.wifiDetails.ssid.ifBlank { "—" }) }
        item { InfoRow("BSSID", info.wifiDetails.bssid.ifBlank { "—" }) }
        item { InfoRow("Signal", "${info.wifiDetails.signalDbm} dBm") }
        item { InfoRow("Frequency", "${info.wifiDetails.frequencyMhz} MHz") }
        item { InfoRow("Link Speed", "${info.wifiDetails.linkSpeedMbps} Mbps") }

        // ── IP Config ─────────────────────────────────────────────────────────
        item { SectionHeader("IP Configuration") }
        item { InfoRow("IP Address", info.ipConfig.ip.ifBlank { "—" }) }
        item { InfoRow("Prefix", info.ipConfig.prefixLength.ifBlank { "—" }) }
        item { InfoRow("Gateway", info.ipConfig.gateway.ifBlank { "—" }) }
        info.ipConfig.dnsServers.forEachIndexed { i, dns ->
            item { InfoRow("DNS ${i + 1}", dns) }
        }

        // ── Interfaces ────────────────────────────────────────────────────────
        item { SectionHeader("Network Interfaces") }
        if (info.interfaces.isEmpty()) {
            item { InfoRow("", "No interfaces found") }
        } else {
            items(info.interfaces) { iface ->
                iface.addresses.forEachIndexed { i, addr ->
                    InfoRow(
                        label = if (i == 0) iface.name else "",
                        value = addr,
                    )
                }
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

@Composable
private fun InfoRow(label: String, value: String) {
    if (label.isBlank()) {
        ListItem(headlineContent = { Text(value) })
    } else {
        ListItem(
            headlineContent = { Text(label, fontWeight = FontWeight.Medium) },
            trailingContent = { Text(value) }
        )
    }
}

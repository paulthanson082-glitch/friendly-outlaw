package com.devtools.android.ui.network

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.devtools.android.modules.network.DnsToolsScreen
import com.devtools.android.modules.network.NetworkInfoScreen
import com.devtools.android.modules.network.PortScannerScreen
import com.devtools.android.modules.network.SpeedTestScreen

private val TABS = listOf("Network Info", "Port Scanner", "DNS Tools", "Speed Test")

@Composable
fun NetworkScreen() {
    var selectedTab by rememberSaveable { mutableIntStateOf(0) }

    Column(modifier = Modifier.fillMaxSize()) {
        TabRow(selectedTabIndex = selectedTab) {
            TABS.forEachIndexed { index, title ->
                Tab(
                    selected = selectedTab == index,
                    onClick = { selectedTab = index },
                    text = { Text(title) },
                )
            }
        }

        when (selectedTab) {
            0 -> NetworkInfoScreen()
            1 -> PortScannerScreen()
            2 -> DnsToolsScreen()
            3 -> SpeedTestScreen()
        }
    }
}

package com.devtools.android.ui.security

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
import com.devtools.android.modules.security.FridaManagerScreen
import com.devtools.android.modules.security.ProcessInspectorScreen
import com.devtools.android.modules.security.RootTerminalScreen
import com.devtools.android.ui.components.RootRequiredCard

private val SECURITY_TABS = listOf("Frida Manager", "Process Inspector", "Root Terminal")

/**
 * Security tab entry point.
 *
 * When [isRooted] is false, shows a [RootRequiredCard] instead of the
 * security tools, so the user knows what is needed.
 *
 * When [isRooted] is true, renders a three-tab layout:
 * 1. Frida Manager — start/stop frida-server, list processes, inject scripts
 * 2. Process Inspector — searchable process list with SIGKILL support
 * 3. Root Terminal — always-root shell with red accent
 */
@Composable
fun SecurityScreen(isRooted: Boolean) {
    if (!isRooted) {
        RootRequiredCard("Security Tools — Frida, Process Inspector, Root Terminal")
        return
    }

    var selectedTab by rememberSaveable { mutableIntStateOf(0) }

    Column(modifier = Modifier.fillMaxSize()) {
        TabRow(selectedTabIndex = selectedTab) {
            SECURITY_TABS.forEachIndexed { index, title ->
                Tab(
                    selected = selectedTab == index,
                    onClick = { selectedTab = index },
                    text = { Text(title) }
                )
            }
        }

        when (selectedTab) {
            0 -> FridaManagerScreen()
            1 -> ProcessInspectorScreen()
            2 -> RootTerminalScreen()
        }
    }
}

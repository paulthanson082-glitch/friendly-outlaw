package com.devtools.android.ui.tools

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
import com.devtools.android.modules.files.FileBrowserScreen
import com.devtools.android.modules.quickref.QuickRefScreen
import com.devtools.android.modules.ssh.SshClientScreen
import com.devtools.android.modules.terminal.ShellTerminalScreen

private val TABS = listOf("SSH Client", "File Browser", "Terminal", "Quick Reference")

@Composable
fun ToolsScreen() {
    var selectedTab by rememberSaveable { mutableIntStateOf(0) }

    Column(modifier = Modifier.fillMaxSize()) {
        TabRow(selectedTabIndex = selectedTab) {
            TABS.forEachIndexed { index, title ->
                Tab(
                    selected = selectedTab == index,
                    onClick = { selectedTab = index },
                    text = { Text(title) }
                )
            }
        }

        when (selectedTab) {
            0 -> SshClientScreen()
            1 -> FileBrowserScreen()
            2 -> ShellTerminalScreen()
            3 -> QuickRefScreen()
        }
    }
}

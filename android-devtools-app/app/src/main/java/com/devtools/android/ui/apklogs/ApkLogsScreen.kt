package com.devtools.android.ui.apklogs

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
import com.devtools.android.modules.apktools.ApkAnalyzerScreen
import com.devtools.android.modules.logcat.LogcatScreen
import com.devtools.android.modules.packages.PackageManagerScreen

private val TABS = listOf("Logcat", "APK Analyzer", "Package Manager")

@Composable
fun ApkLogsScreen() {
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
            0 -> LogcatScreen()
            1 -> ApkAnalyzerScreen()
            2 -> PackageManagerScreen()
        }
    }
}

package com.devtools.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.devtools.android.core.RootDetector
import com.devtools.android.ui.MainScreen
import com.devtools.android.ui.theme.DevToolsTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val isRooted = RootDetector.isRooted
        enableEdgeToEdge()
        setContent {
            DevToolsTheme {
                MainScreen(isRooted = isRooted)
            }
        }
    }
}
